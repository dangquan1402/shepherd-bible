import SwiftUI

struct QuizView: View {
    let lesson: Lesson
    var onFinished: (Int) -> Void

    @State private var index = 0
    @State private var score = 0
    @State private var selected: Int?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                if index < lesson.quiz.count {
                    let q = lesson.quiz[index]
                    Text("Question \(index + 1) of \(lesson.quiz.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(q.prompt)
                        .font(.title3.bold())
                    ForEach(q.choices.indices, id: \.self) { i in
                        Button {
                            selected = i
                        } label: {
                            HStack {
                                Text(q.choices[i])
                                Spacer()
                                if selected == i {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                            }
                            .padding()
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                    Button(index == lesson.quiz.count - 1 ? "Finish" : "Next") {
                        if selected == q.correctIndex { score += 1 }
                        selected = nil
                        if index == lesson.quiz.count - 1 {
                            onFinished(score)
                        } else {
                            index += 1
                        }
                    }
                    .disabled(selected == nil)
                    .buttonStyle(.borderedProminent)
                    .tint(ShepherdTheme.accent)
                }
            }
            .padding()
            .background(ShepherdTheme.softBackground.ignoresSafeArea())
            .navigationTitle("Quiz")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
