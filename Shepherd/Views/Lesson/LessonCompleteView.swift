import SwiftUI

public struct LessonCompleteView: View {
    public let dayIndex: Int
    public let lessonTitle: String
    public let score: Int
    public let totalQuestions: Int
    public let streakCount: Int
    public let oldXP: Int
    public let xpEarned: Int
    public let wasAlreadyCompleted: Bool
    public let companionName: String
    public var onContinue: () -> Void

    @State private var animatedProgress: Double = 0.0
    @State private var showStageUpModal: Bool = false
    @State private var appeared: Bool = false
    @State private var hopTrigger: Int = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        dayIndex: Int = 1,
        lessonTitle: String = "",
        score: Int = 0,
        totalQuestions: Int = 2,
        streakCount: Int = 1,
        oldXP: Int = 0,
        xpEarned: Int = 12,
        wasAlreadyCompleted: Bool = false,
        companionName: String = "Lamb",
        onContinue: @escaping () -> Void
    ) {
        self.dayIndex = dayIndex
        self.lessonTitle = lessonTitle
        self.score = score
        self.totalQuestions = totalQuestions
        self.streakCount = streakCount
        self.oldXP = oldXP
        self.xpEarned = wasAlreadyCompleted ? 0 : xpEarned
        self.wasAlreadyCompleted = wasAlreadyCompleted
        self.companionName = companionName
        self.onContinue = onContinue
    }

    private var newCurrentXP: Int {
        oldXP + xpEarned
    }

    private var oldStage: Int {
        Progression.stage(for: oldXP)
    }

    private var newStage: Int {
        Progression.stage(for: newCurrentXP)
    }

    private var xpIntoCurrentStage: Int {
        newCurrentXP % 50
    }

    private var xpNeededToNextStage: Int {
        50 - xpIntoCurrentStage
    }

    private var stageName: String {
        LambStage(rawValue: newStage)?.name ?? "Newborn"
    }

    public var body: some View {
        ZStack {
            ShepherdTheme.canvasBg.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Stage 1 Celebrating Lamb on Meadow Hill Vignette
                ZStack {
                    HillVignetteView(width: 320, height: 70)
                        .offset(y: 50)

                    AnimatedLambView(
                        stage: 1,
                        expression: .celebrating,
                        displayHeight: 160,
                        isBreathing: false,
                        hopTrigger: hopTrigger
                    )
                }

                VStack(spacing: 8) {
                    Text("Day \(dayIndex) complete")
                        .font(ShepherdTheme.title1Serif())
                        .foregroundStyle(ShepherdTheme.textPrimary)

                    if !lessonTitle.isEmpty {
                        Text(lessonTitle)
                            .font(.subheadline)
                            .foregroundStyle(ShepherdTheme.textSecondary)
                    }
                }

                // Reward Stat Chips
                HStack(spacing: 12) {
                    if wasAlreadyCompleted {
                        RewardStatChip(
                            icon: "checkmark.circle.fill",
                            text: "Already completed",
                            color: ShepherdTheme.accent
                        )
                    } else {
                        RewardStatChip(
                            icon: "sparkles",
                            text: "+\(xpEarned) XP",
                            color: ShepherdTheme.streak,
                            fill: ShepherdTheme.goldSubtle
                        )
                    }

                    RewardStatChip(
                        icon: "flame.fill",
                        text: "\(streakCount) day streak",
                        color: ShepherdTheme.streak,
                        fill: ShepherdTheme.goldSubtle
                    )
                }

                // Companion Stage & XP Progress Card
                VStack(spacing: 10) {
                    HStack {
                        Text("\(companionName) · Stage \(newStage) \(stageName)")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(ShepherdTheme.textPrimary)
                        Spacer()
                        if newStage < 5 {
                            Text("\(xpNeededToNextStage) XP to Stage \(newStage + 1)")
                                .font(.subheadline)
                                .foregroundStyle(ShepherdTheme.textSecondary)
                        } else {
                            Text("Max Stage")
                                .font(.subheadline)
                                .foregroundStyle(ShepherdTheme.textSecondary)
                        }
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(ShepherdTheme.surfaceSunken)
                                .frame(height: 10)

                            Capsule()
                                .fill(ShepherdTheme.accentFill)
                                .frame(width: geo.size.width * CGFloat(animatedProgress), height: 10)
                        }
                    }
                    .frame(height: 10)
                }
                .padding(18)
                .background(ShepherdTheme.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
                .overlay(
                    RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD)
                        .stroke(ShepherdTheme.surfaceBorder, lineWidth: 1)
                )
                .padding(.horizontal, 24)

                Spacer()

                ProminentGlassButton("Continue") {
                    if newStage > oldStage {
                        showStageUpModal = true
                    } else {
                        onContinue()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .sensoryFeedback(.success, trigger: appeared)
        .onAppear {
            appeared = true
            hopTrigger += 1
            let targetProgress = Double(xpIntoCurrentStage) / 50.0
            if reduceMotion {
                animatedProgress = targetProgress
            } else {
                withAnimation(ShepherdTheme.xpFillSpring) {
                    animatedProgress = targetProgress
                }
            }
        }
        .sheet(isPresented: $showStageUpModal) {
            StageUpModalView(oldStage: oldStage, newStage: newStage) {
                showStageUpModal = false
                onContinue()
            }
        }
    }
}
// MARK: - Stage Up Modal (Row 6 Motion Table)

struct StageUpModalView: View {
    let oldStage: Int
    let newStage: Int
    var onDismiss: () -> Void

    @State private var hasTransitioned: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            ShepherdTheme.canvasBg.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    Circle()
                        .stroke(ShepherdTheme.accentFill.opacity(hasTransitioned ? 0.0 : 0.8), lineWidth: 3)
                        .frame(width: hasTransitioned ? 260 : 180, height: hasTransitioned ? 260 : 180)

                    if !hasTransitioned && !reduceMotion {
                        LambView(stage: oldStage, expression: .happy, displayHeight: 140)
                            .scaleEffect(1.08)
                            .opacity(0.4)
                    }

                    LambView(stage: newStage, expression: .happy, displayHeight: 140)
                        .scaleEffect(hasTransitioned ? 1.0 : (reduceMotion ? 1.0 : 0.9))
                }

                VStack(spacing: 8) {
                    Text("Stage Up!")
                        .font(ShepherdTheme.title1Serif())
                        .foregroundStyle(ShepherdTheme.accent)

                    Text("Your lamb grew to Stage \(newStage) · \(LambStage(rawValue: newStage)?.name ?? "")")
                        .font(.headline)
                        .foregroundStyle(ShepherdTheme.textPrimary)
                }

                Spacer()

                ProminentGlassButton("Awesome!") {
                    onDismiss()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: hasTransitioned)
        .onAppear {
            if reduceMotion {
                hasTransitioned = true
            } else {
                withAnimation(ShepherdTheme.stageUpSpring) {
                    hasTransitioned = true
                }
            }
        }
    }
}
