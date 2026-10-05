import SwiftUI

public struct LessonCompleteView: View {
    public let score: Int
    public let totalQuestions: Int
    public let xpEarned: Int
    public let newCurrentXP: Int
    public let newStage: Int
    public let oldStage: Int
    public let streakCount: Int
    public var onContinue: () -> Void

    @State private var animatedProgress: Double = 0.0
    @State private var showStageUpModal: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        score: Int,
        totalQuestions: Int,
        streakCount: Int,
        oldXP: Int,
        onContinue: @escaping () -> Void
    ) {
        self.score = score
        self.totalQuestions = totalQuestions
        self.streakCount = streakCount
        self.xpEarned = 10 + score
        self.newCurrentXP = oldXP + (10 + score)
        self.oldStage = max(1, min(5, 1 + oldXP / 50))
        self.newStage = max(1, min(5, 1 + (oldXP + 10 + score) / 50))
        self.onContinue = onContinue
    }

    private var xpIntoCurrentStage: Int {
        newCurrentXP % 50
    }

    private var xpNeededToNextStage: Int {
        50 - (newCurrentXP % 50)
    }

    public var body: some View {
        ZStack {
            ShepherdTheme.canvasBg.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Celebrating Lamb on vignette
                ZStack {
                    Circle()
                        .fill(ShepherdTheme.accentSubtle.opacity(0.4))
                        .frame(width: 220, height: 220)

                    LambView(
                        stage: newStage,
                        expression: .celebrating,
                        displayHeight: 160
                    )
                }

                VStack(spacing: 8) {
                    Text("Lesson Complete!")
                        .font(ShepherdTheme.title1Serif())
                        .foregroundStyle(ShepherdTheme.textPrimary)

                    Text("You're building a daily habit with God.")
                        .font(.subheadline)
                        .foregroundStyle(ShepherdTheme.textSecondary)
                }

                // Reward Stat Chips
                HStack(spacing: 12) {
                    RewardStatChip(
                        icon: "sparkles",
                        text: "+\(xpEarned) XP",
                        color: ShepherdTheme.accentFill
                    )

                    RewardStatChip(
                        icon: "flame.fill",
                        text: "Streak \(streakCount)",
                        color: ShepherdTheme.accentFill
                    )
                }

                // XP Progress Bar to next stage
                VStack(spacing: 8) {
                    HStack {
                        Text("\(xpIntoCurrentStage) / 50 XP")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(ShepherdTheme.textPrimary)
                        Spacer()
                        if newStage < 5 {
                            Text("\(xpNeededToNextStage) XP to Stage \(newStage + 1)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(ShepherdTheme.textSecondary)
                        } else {
                            Text("Max Stage Reached")
                                .font(.system(size: 13, weight: .medium))
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
        .onAppear {
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
                        .foregroundStyle(ShepherdTheme.accentFill)

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
