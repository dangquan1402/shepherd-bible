import SwiftUI
import SwiftData

public struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @StateObject private var content = ContentStore.shared

    @State private var colorSchemeOverride: ColorScheme? = nil

    public init() {}

    public var body: some View {
        Group {
            if profiles.isEmpty {
                OnboardingFlowView()
            } else {
                MainTabView()
            }
        }
        .environmentObject(content)
        .preferredColorScheme(colorSchemeOverride)
        .task {
            #if DEBUG
            handleLaunchArguments()
            #endif
            content.loadIfNeeded()
            SeedData.ensureDefaults(in: modelContext)
            let activePath = content.activePath(id: profiles.first?.activePathId)
            let completedIDs = Set(((try? modelContext.fetch(FetchDescriptor<LessonProgress>())) ?? []).map(\.lessonId))
            let nextLesson = activePath.flatMap { PathProgress.nextLesson(in: $0, completed: completedIDs) }
            WidgetSyncService.sync(
                context: modelContext,
                activePathTitle: activePath?.title ?? "Pasture",
                nextLessonTitle: nextLesson?.title,
                nextLessonDayIndex: nextLesson?.dayIndex
            )
            StoreKitManager.shared.attach(modelContext)
            await StoreKitManager.shared.updateCustomerProductStatus(context: modelContext)
            #if DEBUG
            applyUITestState()
            #endif
        }
    }

    #if DEBUG
    /// UI tests only. `-uitestCompleted beginner-30:29,mark-30` marks the first 29 lessons of
    /// beginner-30 and every lesson of mark-30 complete (a plain lesson id marks that lesson);
    /// `-uitestPremium` is honoured by StoreKitManager.updateCustomerProductStatus. Lets a UI test
    /// reach day 30 or a Premium lesson without playing through every quiz.
    private func applyUITestState() {
        let args = ProcessInfo.processInfo.arguments
        if let idx = args.firstIndex(of: "-uitestCompleted"), idx + 1 < args.count {
            var ids: [String] = []
            for item in args[idx + 1].split(separator: ",").map(String.init) {
                let parts = item.split(separator: ":").map(String.init)
                if let path = content.paths.first(where: { $0.id == parts[0] }) {
                    let count = parts.count > 1 ? Int(parts[1]) ?? 0 : path.lessons.count
                    ids += path.lessons.prefix(count).map(\.id)
                } else {
                    ids.append(item)
                }
            }
            let existing = Set(((try? modelContext.fetch(FetchDescriptor<LessonProgress>())) ?? []).map(\.lessonId))
            for id in ids where !existing.contains(id) {
                modelContext.insert(LessonProgress(lessonId: id, quizScore: 3))
            }
        }
        try? modelContext.save()
    }

    private func handleLaunchArguments() {
        let args = ProcessInfo.processInfo.arguments
        if let idx = args.firstIndex(of: "-appearance"), idx + 1 < args.count {
            let val = args[idx + 1].lowercased()
            if val == "dark" {
                colorSchemeOverride = .dark
            } else if val == "light" {
                colorSchemeOverride = .light
            }
        }
    }
    #endif
}
