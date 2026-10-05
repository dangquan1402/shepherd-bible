import SwiftUI
import SwiftData

public struct OnboardingFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var step: Int = 0
    @State private var goal: String = "grow_daily"
    @State private var experienceLevel: String = "beginner"
    @State private var dailyMinutes: Int = 5
    @State private var lambName: String = "Barnaby"
    @State private var showPaywall: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                ShepherdTheme.canvasBg.ignoresSafeArea()

                VStack(spacing: 20) {
                    // 6-step progress indicator
                    ProgressView(value: Double(step + 1), total: 6)
                        .tint(ShepherdTheme.accent)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    Group {
                        switch step {
                        case 0: welcomeStep
                        case 1: goalStep
                        case 2: experienceStep
                        case 3: paceStep
                        case 4: nameLambStep
                        default: buildingPlanStep
                        }
                    }

                    Spacer()

                    // Primary Button
                    ProminentGlassButton(step >= 5 ? "See my plan" : "Continue") {
                        advance()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
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

            ZStack {
                Circle()
                    .fill(ShepherdTheme.accentSubtle.opacity(0.4))
                    .frame(width: 220, height: 220)

                LambView(stage: 1, expression: .hello, displayHeight: 140)
            }

            VStack(spacing: 12) {
                Text("Welcome to Shepherd")
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
                optionButton(id: "new", label: "I’m new to faith", selection: $goal)
            }
            .padding(.horizontal, 20)

            Spacer()

            // Lamb peeking at bottom-left
            HStack {
                LambView(stage: 1, expression: .idle, displayHeight: 72)
                    .padding(.leading, 24)
                Spacer()
            }
        }
    }

    // MARK: - Step 2: Experience / Familiarity
    private var experienceStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How familiar are you?")
                .font(ShepherdTheme.title1Serif())
                .foregroundStyle(ShepherdTheme.textPrimary)
                .padding(.horizontal, 20)

            VStack(spacing: 12) {
                optionButton(id: "beginner", label: "Beginner", selection: $experienceLevel)
                optionButton(id: "some", label: "Some experience", selection: $experienceLevel)
                optionButton(id: "regular", label: "I read regularly", selection: $experienceLevel)
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

    // MARK: - Step 3: Pace
    private var paceStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("How many minutes a day?")
                .font(ShepherdTheme.title1Serif())
                .foregroundStyle(ShepherdTheme.textPrimary)
                .padding(.horizontal, 20)

            Picker("Minutes", selection: $dailyMinutes) {
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
                Circle()
                    .fill(ShepherdTheme.accentSubtle.opacity(0.4))
                    .frame(width: 200, height: 200)

                LambView(stage: 1, expression: .hello, displayHeight: 140)
            }

            VStack(spacing: 8) {
                Text("Name your companion")
                    .font(ShepherdTheme.title1Serif())
                    .foregroundStyle(ShepherdTheme.textPrimary)

                Text("He'll walk each day of the journey with you.")
                    .font(.subheadline)
                    .foregroundStyle(ShepherdTheme.textSecondary)
            }

            TextField("Lamb’s name", text: $lambName)
                .font(.system(size: 18, weight: .medium))
                .padding(14)
                .background(ShepherdTheme.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
                .overlay(
                    RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD)
                        .stroke(ShepherdTheme.surfaceBorder, lineWidth: 1)
                )
                .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Step 5: Preparing Plan
    private var buildingPlanStep: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(ShepherdTheme.accentSubtle.opacity(0.4))
                    .frame(width: 180, height: 180)

                LambView(stage: 1, expression: .happy, displayHeight: 120)
            }

            VStack(spacing: 8) {
                Text("Preparing your path…")
                    .font(ShepherdTheme.title1Serif())
                    .foregroundStyle(ShepherdTheme.textPrimary)

                Text("We've set up your 7-day walk with God.")
                    .font(.subheadline)
                    .foregroundStyle(ShepherdTheme.textSecondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(ShepherdTheme.accentFill)
                    Text("Goal: \(goalDisplayTitle)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(ShepherdTheme.textPrimary)
                }

                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(ShepherdTheme.accentFill)
                    Text("Daily goal: \(dailyMinutes) min")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(ShepherdTheme.textPrimary)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ShepherdTheme.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD)
                    .stroke(ShepherdTheme.surfaceBorder, lineWidth: 1)
            )
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private var goalDisplayTitle: String {
        switch goal {
        case "grow_daily": return "Grow a daily habit"
        case "understand": return "Understand the Bible better"
        case "peace": return "Find peace & prayer"
        default: return "I'm new to faith"
        }
    }

    private func optionButton(id: String, label: String, selection: Binding<String>) -> some View {
        let isSelected = selection.wrappedValue == id
        return Button {
            selection.wrappedValue = id
        } label: {
            HStack {
                Text(label)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(ShepherdTheme.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(ShepherdTheme.accentFill)
                } else {
                    Circle()
                        .strokeBorder(ShepherdTheme.surfaceBorder, lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(isSelected ? ShepherdTheme.accentSubtle.opacity(0.3) : ShepherdTheme.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD)
                    .stroke(isSelected ? ShepherdTheme.accent : ShepherdTheme.surfaceBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func advance() {
        if step < 5 {
            withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
                step += 1
            }
        } else {
            showPaywall = true
        }
    }

    private func finishOnboarding() {
        let chosenName = lambName.trimmingCharacters(in: .whitespaces).isEmpty ? "Lamb" : lambName.trimmingCharacters(in: .whitespaces)

        let profile = UserProfile(
            goal: goal,
            experienceLevel: experienceLevel,
            dailyMinutes: dailyMinutes,
            hasCompletedOnboarding: true
        )
        modelContext.insert(profile)

        if let existing = try? modelContext.fetch(FetchDescriptor<Companion>()).first {
            existing.name = chosenName
        } else {
            modelContext.insert(Companion(name: chosenName, stage: 1, xp: 0))
        }

        try? modelContext.save()
        showPaywall = false
    }
}
