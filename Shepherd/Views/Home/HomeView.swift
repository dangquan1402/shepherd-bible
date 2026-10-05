import SwiftUI
import SwiftData

public struct HomeView: View {
    @Binding public var navPath: [Lesson]
    public let namespace: Namespace.ID
    public var onSelectLesson: ((Lesson) -> Void)? = nil

    @EnvironmentObject private var content: ContentStore
    @Query private var streaks: [StreakState]
    @Query private var companions: [Companion]
    @Query private var progress: [LessonProgress]

    private var streak: StreakState? { streaks.first }
    private var companion: Companion? { companions.first }

    private var completedLessonIDs: Set<String> {
        Set(progress.map(\.lessonId))
    }

    private var currentLesson: Lesson? {
        guard let path = content.paths.first else { return nil }
        return path.lessons.first { !completedLessonIDs.contains($0.id) } ?? path.lessons.last
    }

    public init(
        navPath: Binding<[Lesson]>,
        namespace: Namespace.ID,
        onSelectLesson: ((Lesson) -> Void)? = nil
    ) {
        self._navPath = navPath
        self.namespace = namespace
        self.onSelectLesson = onSelectLesson
    }

    public var body: some View {
        NavigationStack(path: $navPath) {
            ScrollView {
                ZStack(alignment: .top) {
                    // 1. Meadow Hills Background
                    MeadowBackgroundView()
                        .frame(height: 1050)

                    // 2. The S-Curve Trail & Nodes
                    if let path = content.paths.first {
                        PathTrailView(
                            lessons: path.lessons,
                            completedIDs: completedLessonIDs,
                            currentLessonID: currentLesson?.id,
                            namespace: namespace,
                            onSelect: { lesson in
                                onSelectLesson?(lesson)
                            }
                        )
                        .padding(.top, 40)
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
        }
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
    let lessons: [Lesson]
    let completedIDs: Set<String>
    let currentLessonID: String?
    let namespace: Namespace.ID
    let onSelect: (Lesson) -> Void

    private let nodeXCoordinates: [CGFloat] = [306, 201, 96, 201, 306, 201, 96]
    private let pitchY: CGFloat = 112

    var body: some View {
        GeometryReader { geo in
            let screenWidth = geo.size.width
            let scaleX = screenWidth / 402.0

            ZStack(alignment: .topLeading) {
                // S-Curve Trail Path
                TrailCurveShape(nodeX: nodeXCoordinates, pitchY: pitchY, scaleX: scaleX, count: lessons.count)
                    .stroke(
                        ShepherdTheme.meadowPathBorder,
                        style: StrokeStyle(lineWidth: 30, lineCap: .round, lineJoin: .round)
                    )
                TrailCurveShape(nodeX: nodeXCoordinates, pitchY: pitchY, scaleX: scaleX, count: lessons.count)
                    .stroke(
                        ShepherdTheme.meadowPath,
                        style: StrokeStyle(lineWidth: 28, lineCap: .round, lineJoin: .round)
                    )

                // Render Nodes
                ForEach(Array(lessons.enumerated()), id: \.element.id) { index, lesson in
                    let xPos = nodeXCoordinates[min(index, nodeXCoordinates.count - 1)] * scaleX
                    let yPos = CGFloat(index) * pitchY + 40

                    let isDone = completedIDs.contains(lesson.id)
                    let isCurrent = lesson.id == currentLessonID
                    let isMilestone = index == lessons.count - 1

                    let nodeState: PathNodeState = {
                        if isCurrent { return .current }
                        if isDone { return .done }
                        if isMilestone { return .milestoneLocked }
                        return .locked
                    }()

                    PathNodeView(dayNumber: lesson.dayIndex, state: nodeState) {
                        onSelect(lesson)
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
                            speechBubble(completedCount: completedIDs.count, dayNumber: lesson.dayIndex)

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
                    Text("Beginner: 7 Days with God")
                        .font(.headline)
                        .foregroundStyle(ShepherdTheme.textPrimary)
                    Text("7 lessons · Day 7 completes the path")
                        .font(.footnote)
                        .foregroundStyle(ShepherdTheme.textSecondary)
                }
                .frame(width: screenWidth)
                .position(x: screenWidth / 2.0, y: CGFloat(lessons.count) * pitchY + 50)
            }
        }
        .frame(height: CGFloat(lessons.count) * pitchY + 120)
    }

    private func speechBubble(completedCount: Int, dayNumber: Int) -> some View {
        let bubbleText: String = {
            if completedCount == 0 {
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
    let nodeX: [CGFloat]
    let pitchY: CGFloat
    let scaleX: CGFloat
    let count: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard count > 0 else { return path }

        let startX = nodeX[0] * scaleX
        let startY: CGFloat = 40
        path.move(to: CGPoint(x: startX, y: startY))

        for i in 1..<count {
            let prevX = nodeX[i - 1] * scaleX
            let prevY = CGFloat(i - 1) * pitchY + 40
            let toX = nodeX[i] * scaleX
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
