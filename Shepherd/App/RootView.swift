import SwiftUI
import SwiftData

public struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @StateObject private var content = ContentStore.shared

    @State private var colorSchemeOverride: ColorScheme? = nil
    @State private var fixtureScreen: String? = nil

    public init() {}

    public var body: some View {
        Group {
            if let fixture = fixtureScreen {
                fixtureView(for: fixture)
            } else if profiles.isEmpty {
                OnboardingFlowView()
            } else {
                MainTabView()
            }
        }
        .environmentObject(content)
        .preferredColorScheme(colorSchemeOverride)
        .task {
            handleLaunchArguments()
            content.loadIfNeeded()
            SeedData.ensureDefaults(in: modelContext)
        }
    }

    private func handleLaunchArguments() {
        let args = ProcessInfo.processInfo.arguments

        // 1. Appearance override
        if let idx = args.firstIndex(of: "-appearance"), idx + 1 < args.count {
            let val = args[idx + 1].lowercased()
            if val == "dark" {
                colorSchemeOverride = .dark
            } else if val == "light" {
                colorSchemeOverride = .light
            }
        }

        // 2. Clean store
        if args.contains("-cleanStore") {
            try? modelContext.delete(model: UserProfile.self)
            try? modelContext.delete(model: Companion.self)
            try? modelContext.delete(model: StreakState.self)
            try? modelContext.delete(model: LessonProgress.self)
            try? modelContext.delete(model: EntitlementState.self)
            try? modelContext.save()
            SeedData.ensureDefaults(in: modelContext)
        }

        // 3. Skip onboarding
        if args.contains("-skipOnboarding") && profiles.isEmpty {
            let profile = UserProfile(goal: "grow_daily", experienceLevel: "beginner", dailyMinutes: 5, hasCompletedOnboarding: true)
            modelContext.insert(profile)
            let companion = Companion(name: "Barnaby", stage: 1, xp: 0)
            modelContext.insert(companion)
            try? modelContext.save()
        }

        // 4. Day 1 Done fixture
        if args.contains("-day1Done") {
            if profiles.isEmpty {
                let profile = UserProfile(goal: "grow_daily", experienceLevel: "beginner", dailyMinutes: 5, hasCompletedOnboarding: true)
                modelContext.insert(profile)
            }
            if let companion = try? modelContext.fetch(FetchDescriptor<Companion>()).first {
                companion.name = "Barnaby"
                companion.xp = 12
                companion.stage = 1
            }
            if let streak = try? modelContext.fetch(FetchDescriptor<StreakState>()).first {
                streak.current = 1
                streak.best = 1
                streak.lastCompletedDate = .now
            }
            modelContext.insert(LessonProgress(lessonId: "day1", quizScore: 2))
            try? modelContext.save()
        }

        // 5. Fixture screen router
        if let idx = args.firstIndex(of: "-screen"), idx + 1 < args.count {
            fixtureScreen = args[idx + 1]
        }
    }

    @ViewBuilder
    private func fixtureView(for screenName: String) -> some View {
        let firstLesson = content.paths.first?.lessons.first ?? Lesson(
            id: "day1",
            dayIndex: 1,
            title: "In the beginning",
            verseRefs: ["GEN.1.1", "GEN.1.3"],
            bodyMarkdown: "God speaks creation into being.",
            prayerPrompt: "Thank you, God.",
            quiz: []
        )

        switch screenName {
        case "Home_DailyPath":
            MainTabView()
        case "Home_Day1Done":
            MainTabView()
        case "Lesson_Reading":
            NavigationStack {
                LessonView(lesson: firstLesson)
            }
        case "Quiz_Unanswered", "Quiz_Selected", "Quiz_Correct", "Quiz_Wrong":
            QuizView(lesson: firstLesson) { _ in }
        case "Lesson_Complete":
            LessonCompleteView(score: 2, totalQuestions: 2, streakCount: 1, oldXP: 0) {}
        case "Companion_Detail":
            NavigationStack {
                CompanionView()
            }
        case "Bible_Reader":
            BibleReaderView()
        case "Settings":
            SettingsView()
        case "Paywall_Trial":
            PaywallView(onContinueFree: {}, onPurchased: {})
        case "Path_Overview":
            NavigationStack {
                PathOverviewView()
            }
        case "Path_Lessons":
            if let path = content.paths.first {
                NavigationStack {
                    PathLessonsListView(path: path)
                }
            } else {
                Text("No path")
            }
        case "Onboarding_Welcome":
            OnboardingFlowView()
        default:
            MainTabView()
        }
    }
}
