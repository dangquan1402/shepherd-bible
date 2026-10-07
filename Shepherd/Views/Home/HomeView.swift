import SwiftUI
import SwiftData

public struct HomeView: View {
    @Binding public var navPath: [Lesson]
    public let namespace: Namespace.ID
    public var onSelectLesson: ((Lesson) -> Void)? = nil
    public var onSelectVerse: ((DailyVerse) -> Void)? = nil

    @EnvironmentObject private var content: ContentStore
    @ObservedObject private var store = StoreKitManager.shared
    @Query private var streaks: [StreakState]
    @Query private var companions: [Companion]
    @Query private var progress: [LessonProgress]
    @Query private var profiles: [UserProfile]
    @Query private var entitlements: [EntitlementState]
    @State private var showPaywall: Bool = false

    private var streak: StreakState? { streaks.first }
    private var companion: Companion? { companions.first }

    private var completedLessonIDs: Set<String> {
        Set(progress.map(\.lessonId))
    }

    private var isPremium: Bool {
        store.isPremium || entitlements.first?.isPremium == true
    }

    private var activePath: StudyPath? {
        content.activePath(id: profiles.first?.activePathId)
    }

    /// nil once every lesson of the path is done (the path-complete state, not "last day again").
    private var currentLesson: Lesson? {
        guard let path = activePath else { return nil }
        return PathProgress.nextLesson(in: path, completed: completedLessonIDs)
    }

    /// Re-read on a day change (significant time change, or the app coming back), so a Home left
    /// open across midnight shows the new day's verse.
    @State private var verseDate: Date = .now
    @Environment(\.scenePhase) private var scenePhase

    private var todayVerse: DailyVerse {
        DailyVerseService.shared.verse(for: verseDate)
    }

    public init(
        navPath: Binding<[Lesson]>,
        namespace: Namespace.ID,
        onSelectLesson: ((Lesson) -> Void)? = nil,
        onSelectVerse: ((DailyVerse) -> Void)? = nil
    ) {
        self._navPath = navPath
        self.namespace = namespace
        self.onSelectLesson = onSelectLesson
        self.onSelectVerse = onSelectVerse
    }

    public var body: some View {
        NavigationStack(path: $navPath) {
            ScrollView {
                ZStack(alignment: .top) {
                    // 1. Meadow Hills Background
                    MeadowBackgroundView()
                        .frame(height: max(1150, PathTrailView.height(for: activePath?.lessons.count ?? 0) + 320))

                    // 2. The S-Curve Trail & Nodes
                    if let path = activePath {
                        VStack(spacing: 16) {
                            VerseOfTheDayCard(verse: todayVerse) {
                                onSelectVerse?(todayVerse)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 12)

                            if currentLesson == nil {
                                PathCompleteCard(path: path)
                                    .padding(.horizontal, 20)
                            }
                            PathTrailView(
                                path: path,
                                completedIDs: completedLessonIDs,
                                currentLessonID: currentLesson?.id,
                                isPremium: isPremium,
                                namespace: namespace,
                                onSelect: { lesson in
                                    onSelectLesson?(lesson)
                                },
                                onSelectLocked: { _ in
                                    showPaywall = true
                                }
                            )
                            // The current node's lamb and speech bubble sit above the trail's frame.
                            .padding(.top, 48)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .background(ShepherdTheme.canvasBg.ignoresSafeArea())
            .scrollEdgeEffectStyle(.soft, for: .top)
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        PathOverviewView()
                    } label: {
                        Image(systemName: "map")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .accessibilityLabel("Path Catalogue")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    StreakChip(streak: streak?.current ?? 0)
                }
            }
            .navigationDestination(for: Lesson.self) { lesson in
                LessonView(lesson: lesson)
                    .navigationTransition(.zoom(sourceID: lesson.id, in: namespace))
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(
                    onContinueFree: { showPaywall = false },
                    onPurchased: { showPaywall = false }
                )
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                verseDate = .now
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { verseDate = .now }
            }
        }
    }
}

// MARK: - End of Path

/// Shown above the trail once every lesson of the active path is done.
struct PathCompleteCard: View {
    let path: StudyPath

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(ShepherdTheme.brand)
                Text("Path complete")
                    .font(ShepherdTheme.title2Serif())
                    .foregroundStyle(ShepherdTheme.textPrimary)
            }
            Text("You finished all \(path.lessons.count) lessons of \(path.title). Pick the path you want to walk next.")
                .font(.subheadline)
                .foregroundStyle(ShepherdTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            NavigationLink {
                PathOverviewView()
            } label: {
                Text("Choose your next path")
                    .font(.body.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 50)
            }
            .buttonStyle(.glassProminent)
            .tint(ShepherdTheme.accentFill)
        }
        .padding(18)
        .shepherdGlassCard(cornerRadius: ShepherdTheme.radiusLG)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Meadow Background with Layered Hills

struct MeadowBackgroundView: View {
    var body: some View {
        Canvas { context, size in
            // Sky gradient
            let skyRect = CGRect(origin: .zero, size: size)
            let skyGrad = Gradient(colors: [ShepherdTheme.meadowSky, ShepherdTheme.meadowSkyBottom])
            context.fill(Path(skyRect), with: .linearGradient(skyGrad, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height * 0.4)))

            // Distant Hill
            var distantHill = Path()
            distantHill.move(to: CGPoint(x: 0, y: size.height))
            distantHill.addLine(to: CGPoint(x: 0, y: 350))
            distantHill.addCurve(to: CGPoint(x: size.width, y: 300), control1: CGPoint(x: size.width * 0.4, y: 390), control2: CGPoint(x: size.width * 0.7, y: 320))
            distantHill.addLine(to: CGPoint(x: size.width, y: size.height))
            distantHill.closeSubpath()
            context.fill(distantHill, with: .color(ShepherdTheme.meadowHillDistant))

            // Mid Hill
            var midHill = Path()
            midHill.move(to: CGPoint(x: 0, y: size.height))
            midHill.addLine(to: CGPoint(x: 0, y: 550))
            midHill.addCurve(to: CGPoint(x: size.width, y: 500), control1: CGPoint(x: size.width * 0.35, y: 600), control2: CGPoint(x: size.width * 0.8, y: 520))
            midHill.addLine(to: CGPoint(x: size.width, y: size.height))
            midHill.closeSubpath()
            context.fill(midHill, with: .color(ShepherdTheme.meadowHillMid))

            // Near Hill
            var nearHill = Path()
            nearHill.move(to: CGPoint(x: 0, y: size.height))
            nearHill.addLine(to: CGPoint(x: 0, y: 780))
            nearHill.addCurve(to: CGPoint(x: size.width, y: 720), control1: CGPoint(x: size.width * 0.45, y: 830), control2: CGPoint(x: size.width * 0.75, y: 750))
            nearHill.addLine(to: CGPoint(x: size.width, y: size.height))
            nearHill.closeSubpath()
            context.fill(nearHill, with: .color(ShepherdTheme.meadowHillNear))
        }
    }
}

// MARK: - S-Curve Path Trail with Nodes and Mascot

struct PathTrailView: View {
    let path: StudyPath
    let completedIDs: Set<String>
    let currentLessonID: String?
    let isPremium: Bool
    let namespace: Namespace.ID
    let onSelect: (Lesson) -> Void
    let onSelectLocked: (Lesson) -> Void

    /// The design's S-curve repeats every 4 nodes: 306, 201, 96, 201, 306, ...
    static let nodeXPattern: [CGFloat] = [306, 201, 96, 201]
    static let pitchY: CGFloat = 112

    static func nodeX(_ index: Int) -> CGFloat {
        nodeXPattern[index % nodeXPattern.count]
    }

    static func height(for lessonCount: Int) -> CGFloat {
        CGFloat(lessonCount) * pitchY + 120
    }

    private var lessons: [Lesson] { path.lessons }
    private var pitchY: CGFloat { Self.pitchY }

    var body: some View {
        GeometryReader { geo in
            let screenWidth = geo.size.width
            let scaleX = screenWidth / 402.0

            ZStack(alignment: .topLeading) {
                // S-Curve Trail Path
                TrailCurveShape(nodeXPattern: Self.nodeXPattern, pitchY: pitchY, scaleX: scaleX, count: lessons.count)
                    .stroke(
                        ShepherdTheme.meadowPathBorder,
                        style: StrokeStyle(lineWidth: 30, lineCap: .round, lineJoin: .round)
                    )
                TrailCurveShape(nodeXPattern: Self.nodeXPattern, pitchY: pitchY, scaleX: scaleX, count: lessons.count)
                    .stroke(
                        ShepherdTheme.meadowPath,
                        style: StrokeStyle(lineWidth: 28, lineCap: .round, lineJoin: .round)
                    )

                // Render Nodes
                ForEach(Array(lessons.enumerated()), id: \.element.id) { index, lesson in
                    let xPos = Self.nodeX(index) * scaleX
                    let yPos = CGFloat(index) * pitchY + 40

                    let isDone = completedIDs.contains(lesson.id)
                    let isCurrent = lesson.id == currentLessonID
                    let isMilestone = index == lessons.count - 1
                    let isOpen = PathAccessPolicy.isUnlocked(lesson, in: path, isPremium: isPremium)

                    let nodeState: PathNodeState = {
                        if isCurrent { return isOpen ? .current : .premiumLocked }
                        if isDone { return .done }
                        if isMilestone { return .milestoneLocked }
                        return .locked
                    }()

                    PathNodeView(dayNumber: lesson.dayIndex, state: nodeState) {
                        if nodeState == .premiumLocked {
                            onSelectLocked(lesson)
                        } else {
                            onSelect(lesson)
                        }
                    }
                    .matchedTransitionSource(id: lesson.id, in: namespace)
                    .position(x: xPos, y: yPos)

                    // Lamb mascot beside current node
                    if isCurrent {
                        let rawX: CGFloat = {
                            if abs(xPos - screenWidth / 2.0) < 15 {
                                return xPos - 120 * scaleX // Center node: put lamb on left
                            } else if xPos > screenWidth / 2.0 {
                                return xPos - 120 * scaleX
                            } else {
                                return xPos + 120 * scaleX
                            }
                        }()
                        let clampedX = min(max(rawX, 60), screenWidth - 60)
                        let lambY = yPos

                        VStack(spacing: 8) {
                            speechBubble(
                                completedCount: PathProgress.completedCount(in: path, completed: completedIDs),
                                dayNumber: lesson.dayIndex,
                                isOpen: isOpen
                            )

                            AnimatedLambView(
                                stage: 1,
                                expression: .idle,
                                displayHeight: 88,
                                isBreathing: true
                            )
                        }
                        .position(x: clampedX, y: lambY - 20)
                    }
                }

                // Footer path title
                VStack(spacing: 4) {
                    Text(path.title)
                        .font(.headline)
                        .foregroundStyle(ShepherdTheme.textPrimary)
                    Text("\(lessons.count) \(lessons.count == 1 ? "lesson" : "lessons") · \(PathAccessPolicy.label(for: path))")
                        .font(.footnote)
                        .foregroundStyle(ShepherdTheme.textSecondary)
                }
                .frame(width: screenWidth)
                .position(x: screenWidth / 2.0, y: CGFloat(lessons.count) * pitchY + 50)
            }
        }
        .frame(height: Self.height(for: lessons.count))
    }

    private func speechBubble(completedCount: Int, dayNumber: Int, isOpen: Bool) -> some View {
        let bubbleText: String = {
            if !isOpen {
                return "Day \(dayNumber) is Premium"
            } else if completedCount == 0 {
                return "Ready for Day \(dayNumber)?"
            } else if completedCount == 1 {
                return "1 day down!"
            } else {
                return "\(completedCount) days down!"
            }
        }()
        return Text(bubbleText)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(ShepherdTheme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .shepherdGlassCard(cornerRadius: ShepherdTheme.radiusPill)
    }
}

// MARK: - Trail S-Curve Geometry

struct TrailCurveShape: Shape {
    let nodeXPattern: [CGFloat]
    let pitchY: CGFloat
    let scaleX: CGFloat
    let count: Int

    private func nodeX(_ index: Int) -> CGFloat {
        nodeXPattern[index % nodeXPattern.count]
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard count > 0 else { return path }

        let startX = nodeX(0) * scaleX
        let startY: CGFloat = 40
        path.move(to: CGPoint(x: startX, y: startY))

        for i in 1..<count {
            let prevX = nodeX(i - 1) * scaleX
            let prevY = CGFloat(i - 1) * pitchY + 40
            let toX = nodeX(i) * scaleX
            let toY = CGFloat(i) * pitchY + 40

            let midY = (prevY + toY) / 2.0
            path.addCurve(
                to: CGPoint(x: toX, y: toY),
                control1: CGPoint(x: prevX, y: midY),
                control2: CGPoint(x: toX, y: midY)
            )
        }
        return path
    }
}
