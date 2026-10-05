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
        case "Home_DailyPath", "Home_Scrolled":
            MainTabView()
        case "Home_Day1Done":
            MainTabView()
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
                MainTabView()
            }
        case "Lesson_Reading":
            NavigationStack {
                LessonView(lesson: firstLesson)
            }
        case "Quiz_Unanswered":
            QuizView(lesson: firstLesson, initialQuestionIndex: 0, initialSelectedChoiceIndex: nil) { _ in }
        case "Quiz_Selected":
            QuizView(lesson: firstLesson, initialQuestionIndex: 0, initialSelectedChoiceIndex: 1) { _ in }
        case "Quiz_Correct":
            QuizView(lesson: firstLesson, initialQuestionIndex: 0, initialSelectedChoiceIndex: 1, initialIsChecked: true, initialIsAnswerCorrect: true) { _ in }
        case "Quiz_Wrong":
            QuizView(lesson: firstLesson, initialQuestionIndex: 0, initialSelectedChoiceIndex: 0, initialIsChecked: true, initialIsAnswerCorrect: false) { _ in }
        case "Quiz_Q2_Wrong":
            QuizView(lesson: firstLesson, initialQuestionIndex: 1, initialSelectedChoiceIndex: 0, initialIsChecked: true, initialIsAnswerCorrect: false) { _ in }
        case "Lesson_Complete":
            LessonCompleteView(score: 2, totalQuestions: 2, streakCount: 1, oldXP: 0) {}
        case "Companion_Detail":
            NavigationStack {
                CompanionView()
            }
        case "Motion_LambHop":
            NavigationStack {
                CompanionView(autoHop: true)
            }
        case "Motion_CheckMorph":
            QuizView(lesson: firstLesson, initialQuestionIndex: 0, initialSelectedChoiceIndex: 1, autoCheck: true) { _ in }
        case "Bible_Reader":
            BibleReaderView()
        case "Bible_Picker":
            BiblePickerSheet(selectedBook: .constant("GEN"), selectedChapter: .constant(1))
        case "Settings":
            SettingsView()
        case "Settings_RestoreResult":
            SettingsView(initialToastMessage: "Purchases successfully restored")
        case "Onboarding_Welcome":
            OnboardingFlowView(initialStep: 0)
        case "Onboarding_Goal":
            OnboardingFlowView(initialStep: 1)
        case "Onboarding_Experience":
            OnboardingFlowView(initialStep: 2)
        case "Onboarding_Pace":
            OnboardingFlowView(initialStep: 3)
        case "Onboarding_NameLamb":
            OnboardingFlowView(initialStep: 4)
        case "Onboarding_BuildingPlan":
            OnboardingFlowView(initialStep: 5)
        case "Paywall_Trial":
            PaywallView(onContinueFree: {}, onPurchased: {})
        case "Paywall_Purchasing":
            PaywallView(forcedState: .purchasing, onContinueFree: {}, onPurchased: {})
        case "Paywall_Pending":
            PaywallView(forcedState: .pending, onContinueFree: {}, onPurchased: {})
        case "Paywall_Failed":
            PaywallView(forcedState: .failed("Payment failed. Please try again."), onContinueFree: {}, onPurchased: {})
        case "Paywall_Restored":
            PaywallView(forcedState: .restored, onContinueFree: {}, onPurchased: {})
        default:
            MainTabView()
        }
    }
}
