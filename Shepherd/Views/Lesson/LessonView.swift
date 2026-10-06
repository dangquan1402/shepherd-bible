import SwiftUI
import SwiftData

public struct LessonView: View {
    public let lesson: Lesson
    @EnvironmentObject private var content: ContentStore
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var streaks: [StreakState]
    @Query private var companions: [Companion]
    @Query private var entitlements: [EntitlementState]

    @ObservedObject private var store = StoreKitManager.shared
    @State private var showPaywall: Bool = false
    @State private var showQuiz: Bool = false
    @State private var showComplete: Bool = false
    @State private var pendingComplete: Bool = false
    @State private var finishedScore: Int = 0
    @State private var completionResult: LessonProgressRecorder.CompletionResult? = nil

    public init(lesson: Lesson) {
        self.lesson = lesson
    }

    private var path: StudyPath? {
        content.path(containing: lesson)
    }

    private var isPremium: Bool {
        store.isPremium || entitlements.first?.isPremium == true
    }

    /// The access gate for every way into a lesson (Today trail, path list, continue accessory).
    private var isUnlocked: Bool {
        guard let path else { return true }
        return PathAccessPolicy.isUnlocked(lesson, in: path, isPremium: isPremium)
    }

    public var body: some View {
        Group {
            if isUnlocked {
                lessonBody
            } else {
                lockedBody
            }
        }
        .navigationTitle("Day \(lesson.dayIndex)")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView(
                onContinueFree: { showPaywall = false },
                onPurchased: { showPaywall = false }
            )
        }
    }

    private var lockedMessage: String {
        guard let path else { return "This lesson is part of Pasture Premium." }
        let intro = "Day \(lesson.dayIndex) of \(path.title) is part of Pasture Premium."
        switch path.freePreviewLessons {
        case 0: return intro
        case 1: return "\(intro) The first lesson is free; Premium opens the rest."
        default: return "\(intro) The first \(path.freePreviewLessons) lessons are free; Premium opens the rest."
        }
    }

    private var lockedBody: some View {
        ScrollView {
            VStack(spacing: 20) {
                LambView(stage: 1, expression: .idle, displayHeight: 110)
                    .padding(.top, 32)

                VStack(spacing: 8) {
                    Text(lesson.title)
                        .font(ShepherdTheme.title1Serif())
                        .foregroundStyle(ShepherdTheme.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(lockedMessage)
                        .font(.body)
                        .foregroundStyle(ShepherdTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                ProminentGlassButton("See Premium", icon: "lock.open") {
                    showPaywall = true
                }
                .padding(.top, 8)

                Button("Not now") { dismiss() }
                    .font(.body.weight(.medium))
                    .foregroundStyle(ShepherdTheme.textSecondary)
            }
            .padding(.horizontal, 24)
        }
        .background(ShepherdTheme.canvasBg.ignoresSafeArea())
    }

    private var lessonBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Eyebrow (sentence case per spec)
                Text(path?.title ?? "")
                    .font(ShepherdTheme.scriptureEyebrow())
                    .foregroundStyle(ShepherdTheme.accent)
                    .padding(.top, 8)

                // Title
                Text(lesson.title)
                    .font(ShepherdTheme.largeTitleSerif())
                    .foregroundStyle(ShepherdTheme.textPrimary)

                // Scripture Verses
                VStack(spacing: 14) {
                    ForEach(lesson.verseRefs, id: \.self) { ref in
                        VerseCard(
                            reference: ref,
                            translation: "WEB",
                            text: content.verse(ref: ref) ?? "Loading…"
                        )
                    }
                }

                // Reflection Section Header & Markdown Body
                VStack(alignment: .leading, spacing: 10) {
                    Text("Reflection")
                        .font(.headline)
                        .foregroundStyle(ShepherdTheme.accent)

                    Text(LocalizedStringKey(lesson.bodyMarkdown))
                        .font(.body)
                        .foregroundStyle(ShepherdTheme.textPrimary)
                        .lineSpacing(6)
                }
                .padding(.vertical, 8)

                // Prayer Prompt Card
                if let prayer = lesson.prayerPrompt {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "hands.and.sparkles.fill")
                                .foregroundStyle(ShepherdTheme.accent)
                            Text("Prayer")
                                .font(.headline)
                                .foregroundStyle(ShepherdTheme.accent)
                        }

                        Text(prayer)
                            .font(ShepherdTheme.scriptureBody())
                            .foregroundStyle(ShepherdTheme.textPrimary)
                            .lineSpacing(6)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ShepherdTheme.surfaceSunken)
                    .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
                }

                // CTA: Take the quiz
                ProminentGlassButton("Take the quiz", icon: "checkmark.circle") {
                    showQuiz = true
                }
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
        }
        .background(ShepherdTheme.canvasBg.ignoresSafeArea())
        .scrollEdgeEffectStyle(.soft, for: .top)
        .fullScreenCover(isPresented: $showQuiz, onDismiss: {
            if pendingComplete {
                pendingComplete = false
                showComplete = true
            }
        }) {
            QuizView(lesson: lesson) { score in
                recordCompletion(score: score)
            }
        }
        .fullScreenCover(isPresented: $showComplete) {
            LessonCompleteView(
                dayIndex: lesson.dayIndex,
                lessonTitle: lesson.title,
                score: finishedScore,
                totalQuestions: lesson.quiz.count,
                streakCount: completionResult?.streakCount ?? streaks.first?.current ?? 1,
                oldXP: completionResult?.oldXP ?? companions.first?.xp ?? 0,
                xpEarned: completionResult?.xpAwarded ?? 12,
                wasAlreadyCompleted: completionResult?.wasAlreadyCompleted ?? false,
                companionName: companions.first?.name ?? "Lamb"
            ) {
                showComplete = false
                dismiss()
            }
        }
    }

    private func recordCompletion(score: Int) {
        let result = LessonProgressRecorder.complete(lesson: lesson, score: score, context: modelContext, isPremium: isPremium)
        completionResult = result
        finishedScore = score
        pendingComplete = true
        showQuiz = false
    }
}
