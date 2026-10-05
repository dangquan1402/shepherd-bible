import SwiftUI
import SwiftData

public struct LessonView: View {
    public let lesson: Lesson
    @EnvironmentObject private var content: ContentStore
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var streaks: [StreakState]
    @Query private var companions: [Companion]

    @State private var showQuiz: Bool = false
    @State private var showComplete: Bool = false
    @State private var finishedScore: Int = 0
    @State private var oldXP: Int = 0

    public init(lesson: Lesson) {
        self.lesson = lesson
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Eyebrow
                Text("BEGINNER: 7 DAYS WITH GOD")
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
                            text: content.verse(ref: ref) ?? "Verse text not in sample bundle."
                        )
                    }
                }

                // Lesson Body Markdown
                VStack(alignment: .leading, spacing: 12) {
                    Text(LocalizedStringKey(lesson.bodyMarkdown))
                        .font(.system(size: 17))
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
        .navigationTitle("Day \(lesson.dayIndex)")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showQuiz) {
            QuizView(lesson: lesson) { score in
                completeLesson(score: score)
            }
        }
        .fullScreenCover(isPresented: $showComplete) {
            LessonCompleteView(
                score: finishedScore,
                totalQuestions: lesson.quiz.count,
                streakCount: streaks.first?.current ?? 1,
                oldXP: oldXP
            ) {
                showComplete = false
                dismiss()
            }
        }
    }

    private func completeLesson(score: Int) {
        showQuiz = false
        finishedScore = score

        let companion = companions.first
        oldXP = companion?.xp ?? 0

        // Persist progress and update models
        let progress = LessonProgress(lessonId: lesson.id, quizScore: score)
        modelContext.insert(progress)

        let streak = streaks.first
        streak?.markCompleted()

        companion?.addXP(10 + score)
        try? modelContext.save()

        // Present reward complete screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showComplete = true
        }
    }
}
