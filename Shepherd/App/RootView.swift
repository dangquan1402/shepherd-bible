import SwiftUI
import SwiftData

public struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
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
            resetForUITestIfAsked()
            #endif
            content.loadIfNeeded()
            SeedData.ensureDefaults(in: modelContext)
            StoreKitManager.shared.attach(modelContext)
            await StoreKitManager.shared.updateCustomerProductStatus(context: modelContext)
            #if DEBUG
            applyUITestState()
            #endif
            await DailyReminder.shared.refresh(context: modelContext)
        }
        .onChange(of: scenePhase) { _, phase in
            JournalAuthService.shared.scenePhaseChanged(to: phase)
            // A new day may have started: refill the reminder window and re-check today's lesson.
            guard phase == .active else { return }
            Task { await DailyReminder.shared.refresh(context: modelContext) }
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
        if args.contains("-uitestResetBibleUserData") {
            try? modelContext.delete(model: BibleHighlight.self)
            try? modelContext.delete(model: BibleBookmark.self)
            try? modelContext.delete(model: BibleNote.self)
        }
        try? modelContext.save()
    }

    /// UI tests only. `-uitestReset` starts from a fresh install's state (no profile, progress,
    /// rating-prompt or reminder flags, no journal entries or prayers, journal lock off) without
    /// reinstalling, so tests in one run stay independent.
    private func resetForUITestIfAsked() {
        guard ProcessInfo.processInfo.arguments.contains("-uitestReset") else { return }
        try? modelContext.delete(model: LessonProgress.self)
        try? modelContext.delete(model: UserProfile.self)
        try? modelContext.delete(model: Companion.self)
        try? modelContext.delete(model: StreakState.self)
        try? modelContext.delete(model: EntitlementState.self)
        try? modelContext.delete(model: JournalEntry.self)
        try? modelContext.delete(model: PrayerRequest.self)
        try? modelContext.delete(model: BibleHighlight.self)
        try? modelContext.delete(model: BibleBookmark.self)
        try? modelContext.delete(model: BibleNote.self)
        try? modelContext.save()
        JournalAuthService.shared.isLockEnabled = false
        JournalAuthService.shared.isUnlocked = true
        for key in [ReviewPrompter.promptedVersionKey, ReminderSettings.enabledKey, ReminderSettings.hourKey, ReminderSettings.minuteKey] {
            UserDefaults.standard.removeObject(forKey: key)
        }
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
