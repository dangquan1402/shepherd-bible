import SwiftUI
import SwiftData

public struct OnboardingFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var content: ContentStore
    @State private var step: Int = 0
    @State private var goal: String = "grow_daily"
    @State private var experienceLevel: String = "beginner"
    @State private var dailyMinutes: Int = 5
    @State private var lambName: String = ""
    @State private var showPaywall: Bool = false
    @State private var reminderTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: .now) ?? .now
    @State private var isAskingForReminder: Bool = false

    private static let reminderStep = 5
    private static let planStep = 6

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                ShepherdTheme.canvasBg.ignoresSafeArea()

                VStack(spacing: 20) {
                    // Segmented step progress
                    HStack(spacing: 6) {
                        ForEach(0...Self.planStep, id: \.self) { i in
                            Capsule()
                                .fill(i <= step ? ShepherdTheme.accentFill : ShepherdTheme.surfaceSunken)
                                .frame(height: 4)
                                .animation(.easeInOut(duration: 0.25), value: step)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    Group {
                        switch step {
                        case 0: welcomeStep
                        case 1: goalStep
                        case 2: experienceStep
                        case 3: paceStep
                        case 4: nameLambStep
                        case Self.reminderStep: reminderStepView
                        default: buildingPlanStep
                        }
                    }

                    Spacer()

                    // Primary Button
                    if step == Self.reminderStep {
                        VStack(spacing: 12) {
                            ProminentGlassButton("Remind me", icon: "bell") {
                                acceptReminder()
                            }
                            .disabled(isAskingForReminder)

                            Button("Not now") { advance() }
                                .font(.body.weight(.medium))
                                .foregroundStyle(ShepherdTheme.textSecondary)
                                .frame(minHeight: 44)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    } else {
                        ProminentGlassButton(step >= Self.planStep ? "See my plan" : "Continue") {
                            advance()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
            .toolbar {
                if step > 0 {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
                                step -= 1
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                        }
                        .accessibilityLabel("Back")
                    }
                }
            }
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView(
                    onContinueFree: finishOnboarding,
                    onPurchased: finishOnboarding
                )
            }
        }
    }

    // MARK: - Step 0: Welcome
    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()

            BrandLockup(.regular)
                .padding(.bottom, 24)

            ZStack {
                HillVignetteView(width: 320, height: 70)
                    .offset(y: 45)

                LambView(stage: 1, expression: .hello, displayHeight: 140)
            }

            VStack(spacing: 12) {
                Text("Welcome to Pasture")
                    .font(ShepherdTheme.largeTitleSerif())
                    .foregroundStyle(ShepherdTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("A few minutes a day. Scripture that sticks. Everything stays on your phone.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(ShepherdTheme.textSecondary)
                    .padding(.horizontal, 20)
            }

            Spacer()
        }
    }

    // MARK: - Step 1: Goal
    private var goalStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What’s your goal?")
                .font(ShepherdTheme.title1Serif())
                .foregroundStyle(ShepherdTheme.textPrimary)
                .padding(.horizontal, 20)

            VStack(spacing: 12) {
                optionButton(id: "grow_daily", label: "Grow a daily habit", selection: $goal)
                optionButton(id: "understand", label: "Understand the Bible better", selection: $goal)
                optionButton(id: "peace", label: "Find peace & prayer", selection: $goal)
            }
            .padding(.horizontal, 20)

            Spacer()

            HStack {
                LambView(stage: 1, expression: .idle, displayHeight: 72)
                    .padding(.leading, 24)
                Spacer()
            }
        }
    }

    // MARK: - Step 2: Experience
    private var experienceStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How familiar are you with the Bible?")
                .font(ShepherdTheme.title1Serif())
                .foregroundStyle(ShepherdTheme.textPrimary)
                .padding(.horizontal, 20)

            VStack(spacing: 12) {
                optionButton(id: "beginner", label: "Brand new", selection: $experienceLevel)
                optionButton(id: "some", label: "Some experience", selection: $experienceLevel)
                optionButton(id: "deep", label: "Read it regularly", selection: $experienceLevel)
            }
            .padding(.horizontal, 20)

            Spacer()

            HStack {
                Spacer()
                LambView(stage: 1, expression: .idle, displayHeight: 72)
                    .padding(.trailing, 24)
            }
        }
    }

    // MARK: - Step 3: Pace
    private var paceStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How much time each day?")
                .font(ShepherdTheme.title1Serif())
                .foregroundStyle(ShepherdTheme.textPrimary)
                .padding(.horizontal, 20)

            Picker("Daily Minutes", selection: $dailyMinutes) {
                Text("5 min").tag(5)
                Text("10 min").tag(10)
                Text("15 min").tag(15)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)

            Text("No rush. Five quiet minutes is enough to start.")
                .font(.subheadline)
                .foregroundStyle(ShepherdTheme.textSecondary)
                .padding(.horizontal, 20)

            Spacer()

            HStack {
                LambView(stage: 1, expression: .idle, displayHeight: 72)
                    .padding(.leading, 24)
                Spacer()
            }
        }
    }

    // MARK: - Step 4: Name Companion
    private var nameLambStep: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                HillVignetteView(width: 320, height: 70)
                    .offset(y: 45)

                LambView(stage: 1, expression: .hello, displayHeight: 140)
            }

            VStack(spacing: 8) {
                Text("Name your companion")
                    .font(ShepherdTheme.title1Serif())
                    .foregroundStyle(ShepherdTheme.textPrimary)

                Text("Your lamb grows as you learn.")
                    .font(.subheadline)
                    .foregroundStyle(ShepherdTheme.textSecondary)
            }

            TextField("Lamb’s name", text: $lambName)
                .font(.body)
                .padding(14)
                .background(ShepherdTheme.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
                .overlay(
                    RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD)
                        .stroke(ShepherdTheme.surfaceBorder, lineWidth: 1)
                )
                .padding(.horizontal, 20)

            Spacer()
        }
    }

    // MARK: - Step 5: Daily reminder (optional; asks for permission only on "Remind me")
    private var reminderStepView: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                HillVignetteView(width: 320, height: 70)
                    .offset(y: 45)

                LambView(stage: 1, expression: .sleepy, displayHeight: 140)
            }

            VStack(spacing: 8) {
                Text("Want a gentle daily reminder?")
                    .font(ShepherdTheme.title1Serif())
                    .foregroundStyle(ShepherdTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("One quiet nudge a day, at a time you choose. Change it or turn it off in Settings.")
                    .font(.subheadline)
                    .foregroundStyle(ShepherdTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            DatePicker(selection: $reminderTime, displayedComponents: .hourAndMinute) {
                Text("Remind me at")
                    .font(.body)
                    .foregroundStyle(ShepherdTheme.textPrimary)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 56)
            .background(ShepherdTheme.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD)
                    .stroke(ShepherdTheme.surfaceBorder, lineWidth: 1)
            )
            .padding(.horizontal, 20)

            Spacer()
        }
    }

    // MARK: - Step 6: Building Plan
    /// Scrolls when the suggested-path card does not fit (accessibility text sizes), so the
    /// "See my plan" button below always stays on screen.
    private var buildingPlanStep: some View {
        ViewThatFits(in: .vertical) {
            buildingPlanContent
            ScrollView {
                buildingPlanContent
                    .padding(.vertical, 8)
            }
        }
    }

    private var buildingPlanContent: some View {
        VStack(spacing: 20) {
            Spacer()

            AnimatedLambView(stage: 1, expression: .happy, displayHeight: 120, isBreathing: true)

            VStack(spacing: 8) {
                Text("Preparing your path…")
                    .font(ShepherdTheme.title1Serif())
                    .foregroundStyle(ShepherdTheme.textPrimary)

                Text("A first path picked from your answers.")
                    .font(.subheadline)
                    .foregroundStyle(ShepherdTheme.textSecondary)
            }

            // Summary Card
            VStack(alignment: .leading, spacing: 10) {
                if let path = suggestedPath {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Suggested path")
                            .font(.subheadline)
                            .foregroundStyle(ShepherdTheme.textSecondary)
                        Text(path.title)
                            .font(.headline)
                            .foregroundStyle(ShepherdTheme.textPrimary)
                        Text("\(path.lessons.count) lessons · \(PathAccessPolicy.label(for: path))")
                            .font(.footnote)
                            .foregroundStyle(path.access == .premium ? ShepherdTheme.accent : ShepherdTheme.textSecondary)
                        if path.access == .premium, let free = freeAlternative {
                            Text("Or start free with \(free.title).")
                                .font(.footnote)
                                .foregroundStyle(ShepherdTheme.textSecondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    Divider()
                }
                summaryRow(title: "Goal", value: goalLabel(goal))
                summaryRow(title: "Level", value: levelLabel(experienceLevel))
                summaryRow(title: "Pace", value: "\(dailyMinutes) minutes daily")
                summaryRow(title: "Companion", value: lambName.trimmingCharacters(in: .whitespaces).isEmpty ? "Lamb" : lambName.trimmingCharacters(in: .whitespaces))
            }
            .padding(16)
            .shepherdGlassCard(cornerRadius: ShepherdTheme.radiusLG)
            .padding(.horizontal, 20)

            Spacer()
        }
    }

    private var suggestedPath: StudyPath? {
        PathRecommender.recommendedPath(goal: goal, level: experienceLevel, in: content.paths)
    }

    private var freeAlternative: StudyPath? {
        content.paths.first { $0.access != .premium }
    }

    private func summaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(ShepherdTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ShepherdTheme.textPrimary)
        }
    }

    private func goalLabel(_ g: String) -> String {
        switch g {
        case "grow_daily": return "Daily habit"
        case "understand": return "Understand Bible"
        case "peace": return "Peace & prayer"
        default: return g
        }
    }

    private func levelLabel(_ l: String) -> String {
        switch l {
        case "beginner": return "Brand new"
        case "some": return "Some experience"
        case "deep": return "Regular reader"
        default: return l
        }
    }

    private func optionButton(id: String, label: String, selection: Binding<String>) -> some View {
        let isSelected = selection.wrappedValue == id
        return Button {
            selection.wrappedValue = id
        } label: {
            HStack {
                Text(label)
                    .font(.body.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(ShepherdTheme.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(ShepherdTheme.accentFill)
                }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 56)
            .background(isSelected ? ShepherdTheme.accentSubtle.opacity(0.3) : ShepherdTheme.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD)
                    .stroke(isSelected ? ShepherdTheme.accent : ShepherdTheme.surfaceBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    /// Asks iOS for permission (the only place onboarding does) and schedules the reminder.
    /// Either answer moves on: Settings explains a refusal if the user turns the reminder on later.
    private func acceptReminder() {
        guard !isAskingForReminder else { return }
        isAskingForReminder = true
        let parts = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        Task {
            await DailyReminder.shared.enable(
                hour: parts.hour ?? 8,
                minute: parts.minute ?? 0,
                lesson: suggestedPath?.lessons.first.map(ReminderLesson.init)
            )
            isAskingForReminder = false
            advance()
        }
    }

    private func advance() {
        if step < Self.planStep {
            withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
                step += 1
            }
        } else {
            showPaywall = true
        }
    }

    private func finishOnboarding() {
        OnboardingStore.complete(
            goal: goal,
            experience: experienceLevel,
            minutes: dailyMinutes,
            name: lambName,
            activePathId: suggestedPath?.id,
            context: modelContext
        )
        showPaywall = false
    }
}
