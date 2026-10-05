import SwiftUI
import SwiftData

struct LessonView: View {
    let lesson: Lesson
    @EnvironmentObject private var content: ContentStore
    @Environment(\.modelContext) private var modelContext
    @Query private var streaks: [StreakState]
    @Query private var companions: [Companion]
    @State private var showQuiz = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(lesson.title)
                    .font(.largeTitle.bold())

                ForEach(lesson.verseRefs, id: \.self) { ref in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(ref)
                            .font(.caption.bold())
                            .foregroundStyle(ShepherdTheme.accent)
                        Text(content.verse(ref: ref) ?? "Verse text not in sample bundle.")
                            .font(.body)
                    }
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Text(LocalizedStringKey(lesson.bodyMarkdown))
                    .font(.body)

                if let prayer = lesson.prayerPrompt {
                    Text("Prayer")
                        .font(.headline)
                    Text(prayer)
                        .foregroundStyle(.secondary)
                }

                Button("Take the quiz") { showQuiz = true }
                    .buttonStyle(.borderedProminent)
                    .tint(ShepherdTheme.accent)
            }
            .padding()
        }
        .background(ShepherdTheme.softBackground.ignoresSafeArea())
        .navigationTitle("Day \(lesson.dayIndex)")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showQuiz) {
            QuizView(lesson: lesson) { score in
                complete(score: score)
            }
        }
    }

    private func complete(score: Int) {
        modelContext.insert(LessonProgress(lessonId: lesson.id, quizScore: score))
        streaks.first?.markCompleted()
        companions.first?.addXP(10 + score)
        try? modelContext.save()
        showQuiz = false
    }
}
