import SwiftUI
import SwiftData

public struct PathOverviewView: View {
    @EnvironmentObject private var content: ContentStore
    @Query private var progress: [LessonProgress]
    @Query private var profiles: [UserProfile]

    public init() {}

    private var completedIDs: Set<String> {
        Set(progress.map(\.lessonId))
    }

    private var activePathID: String? {
        content.activePath(id: profiles.first?.activePathId)?.id
    }

    public var body: some View {
        List {
            Section("Paths") {
                ForEach(content.paths) { path in
                    NavigationLink {
                        PathLessonsListView(path: path)
                    } label: {
                        PathCatalogRow(
                            path: path,
                            completedCount: PathProgress.completedCount(in: path, completed: completedIDs),
                            isActive: path.id == activePathID
                        )
                    }
                }
            }

            // Only while content has a single path; real paths replace this row.
            if content.paths.count == 1 {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(ShepherdTheme.textTertiary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("More paths are coming")
                                .font(.headline)
                                .foregroundStyle(ShepherdTheme.textSecondary)
                            Text("New devotional paths will be added in future updates.")
                                .font(.footnote)
                                .foregroundStyle(ShepherdTheme.textTertiary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Paths")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct PathCatalogRow: View {
    let path: StudyPath
    let completedCount: Int
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(path.title)
                    .font(.headline)
                    .foregroundStyle(ShepherdTheme.textPrimary)
                Spacer()
                if isActive {
                    Text("Current")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(ShepherdTheme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(ShepherdTheme.accentSubtle)
                        .clipShape(Capsule())
                }
            }
            if let subtitle = path.subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(ShepherdTheme.textSecondary)
            }
            HStack(spacing: 6) {
                Image(systemName: path.access == .premium ? "lock.open" : "checkmark.seal")
                    .font(.caption.weight(.semibold))
                Text("\(path.lessons.count) lessons · \(PathAccessPolicy.label(for: path))")
            }
            .font(.footnote)
            .foregroundStyle(path.access == .premium ? ShepherdTheme.accent : ShepherdTheme.textSecondary)
            if completedCount > 0 {
                Text("\(completedCount) of \(path.lessons.count) done")
                    .font(.footnote)
                    .foregroundStyle(ShepherdTheme.textTertiary)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}

public struct PathLessonsListView: View {
    public let path: StudyPath
    @EnvironmentObject private var content: ContentStore
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var store = StoreKitManager.shared
    @Query private var progress: [LessonProgress]
    @Query private var profiles: [UserProfile]
    @Query private var entitlements: [EntitlementState]
    @State private var showPaywall: Bool = false

    public init(path: StudyPath) {
        self.path = path
    }

    private var isPremium: Bool {
        store.isPremium || entitlements.first?.isPremium == true
    }

    private var isActive: Bool {
        content.activePath(id: profiles.first?.activePathId)?.id == path.id
    }

    private var nextDayIndex: Int {
        let completedIDs = Set(progress.filter { $0.isCompleted }.map(\.lessonId))
        return PathProgress.nextLesson(in: path, completed: completedIDs)?.dayIndex ?? path.lessons.count + 1
    }

    public var body: some View {
        List {
            Section {
                if isActive {
                    Label("You are following this path", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(ShepherdTheme.accent)
                } else {
                    Button {
                        followPath()
                    } label: {
                        Label("Follow this path on Today", systemImage: "arrow.right.circle")
                            .foregroundStyle(ShepherdTheme.accentFill)
                    }
                }
            } footer: {
                Text("\(path.lessons.count) lessons · \(PathAccessPolicy.label(for: path))")
            }

            Section {
                ForEach(path.lessons) { lesson in
                    row(for: lesson)
                }
            }
        }
        .navigationTitle(path.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView(
                onContinueFree: { showPaywall = false },
                onPurchased: { showPaywall = false }
            )
        }
    }

    @ViewBuilder
    private func row(for lesson: Lesson) -> some View {
        let isOpen = PathAccessPolicy.isUnlocked(lesson, in: path, isPremium: isPremium)
        let isReached = lesson.dayIndex <= nextDayIndex
        let formattedRefs = ContentStore.displayRefs(lesson.verseRefs)

        if !isOpen {
            Button {
                showPaywall = true
            } label: {
                lessonLabel(lesson, refs: formattedRefs, dimmed: true, trailingIcon: "lock.fill", trailingText: "Premium")
            }
            .accessibilityLabel("Day \(lesson.dayIndex), \(lesson.displayTitle), Premium")
        } else if isReached {
            NavigationLink {
                LessonView(lesson: lesson)
            } label: {
                lessonLabel(lesson, refs: formattedRefs, dimmed: false, trailingIcon: nil, trailingText: nil)
            }
        } else {
            lessonLabel(lesson, refs: formattedRefs, dimmed: true, trailingIcon: "lock.fill", trailingText: nil)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Day \(lesson.dayIndex), locked")
        }
    }

    private func lessonLabel(_ lesson: Lesson, refs: String, dimmed: Bool, trailingIcon: String?, trailingText: String?) -> some View {
        HStack(spacing: 14) {
            Text("Day \(lesson.dayIndex)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(dimmed ? ShepherdTheme.textTertiary : ShepherdTheme.accent)
                .frame(width: 52, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(lesson.displayTitle)
                    .font(.headline)
                    .foregroundStyle(dimmed ? ShepherdTheme.textTertiary : ShepherdTheme.textPrimary)

                Text(refs)
                    .font(.caption)
                    .foregroundStyle(dimmed ? ShepherdTheme.textTertiary : ShepherdTheme.textSecondary)
            }

            Spacer()

            if let trailingText {
                Text(trailingText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ShepherdTheme.accent)
            }
            if let trailingIcon {
                Image(systemName: trailingIcon)
                    .font(.subheadline)
                    .foregroundStyle(trailingText == nil ? ShepherdTheme.textTertiary : ShepherdTheme.accent)
            }
        }
        .padding(.vertical, 4)
    }

    private func followPath() {
        guard let profile = profiles.first else { return }
        profile.activePathId = path.id
        try? modelContext.save()
    }
}
