import SwiftUI

public struct QuizView: View {
    public let lesson: Lesson
    public var onFinished: (Int) -> Void

    @EnvironmentObject private var content: ContentStore
    @Environment(\.dismiss) private var dismiss

    @State private var questionIndex: Int = 0
    @State private var selectedChoiceIndex: Int? = nil
    @State private var isChecked: Bool = false
    @State private var isAnswerCorrect: Bool = false
    @State private var totalScore: Int = 0
    @State private var answeredCount: Int = 0
    @State private var feedbackResult: QuizFeedbackData? = nil

    @Namespace private var morphNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public struct QuizFeedbackData: Equatable {
        public let isCorrect: Bool
        public let title: String
        public let explain: String?
        public let correctChoice: String
        public let verseRef: String
        public let verseText: String
    }

    public init(lesson: Lesson, onFinished: @escaping (Int) -> Void) {
        self.lesson = lesson
        self.onFinished = onFinished
    }

    private var currentQuestion: QuizQuestion {
        lesson.quiz[min(questionIndex, lesson.quiz.count - 1)]
    }

    private var quizProgress: Double {
        guard !lesson.quiz.isEmpty else { return 0 }
        return Double(answeredCount) / Double(lesson.quiz.count)
    }

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ShepherdTheme.canvasBg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Progress bar & Eyebrow
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DAY \(lesson.dayIndex)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(ShepherdTheme.accent)

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(ShepherdTheme.surfaceSunken)
                                        .frame(height: 6)

                                    Capsule()
                                        .fill(ShepherdTheme.accentFill)
                                        .frame(width: geo.size.width * CGFloat(quizProgress), height: 6)
                                        .animation(.easeInOut(duration: 0.3), value: quizProgress)
                                }
                            }
                            .frame(height: 6)
                        }
                        .padding(.top, 8)

                        // Question Prompt
                        Text(currentQuestion.prompt)
                            .font(.system(size: 22, weight: .bold, design: .serif))
                            .foregroundStyle(ShepherdTheme.textPrimary)
                            .padding(.top, 4)

                        // Choices list
                        VStack(spacing: 12) {
                            let letters = ["A", "B", "C", "D"]
                            ForEach(Array(currentQuestion.choices.enumerated()), id: \.offset) { i, choice in
                                let letter = i < letters.count ? letters[i] : "\(i + 1)"
                                let state: ChoiceRowState = {
                                    if !isChecked {
                                        return selectedChoiceIndex == i ? .selected : .neutral
                                    }
                                    if i == currentQuestion.correctIndex {
                                        return isAnswerCorrect ? .correct : .revealed
                                    }
                                    if selectedChoiceIndex == i {
                                        return .wrong
                                    }
                                    return .neutral
                                }()

                                ChoiceRow(letter: letter, text: choice, state: state) {
                                    if !isChecked {
                                        selectedChoiceIndex = i
                                    }
                                }
                            }
                        }

                        // Space for the morphing feedback sheet / button at the bottom
                        Spacer()
                            .frame(height: 380)
                    }
                    .padding(.horizontal, 20)
                }

                // Scrim overlay behind feedback sheet
                if feedbackResult != nil {
                    Color.black.opacity(0.15)
                        .ignoresSafeArea()
                        .transition(.opacity)
                }

                // Morph A: GlassEffectContainer morphing Check button into FeedbackSheet
                GlassEffectContainer(spacing: 16) {
                    if let result = feedbackResult {
                        QuizFeedbackSheet(result: result) {
                            advanceToNextQuestion()
                        }
                        .glassEffectID("quiz_action", in: morphNamespace)
                    } else {
                        Button {
                            withAnimation(ShepherdTheme.morphSpring) {
                                evaluateAnswer()
                            }
                        } label: {
                            Text("Check")
                                .font(.system(size: 17, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(ShepherdTheme.accentFill)
                        .glassEffectID("quiz_action", in: morphNamespace)
                        .disabled(selectedChoiceIndex == nil)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sensoryFeedback(.success, trigger: isChecked && isAnswerCorrect)
            .sensoryFeedback(.warning, trigger: isChecked && !isAnswerCorrect)
        }
    }

    private func evaluateAnswer() {
        guard let selected = selectedChoiceIndex else { return }
        isChecked = true
        let correct = (selected == currentQuestion.correctIndex)
        isAnswerCorrect = correct
        if correct {
            totalScore += 1
        }
        answeredCount += 1

        // M5 rule: find answering verse
        let correctChoiceText = currentQuestion.choices[currentQuestion.correctIndex]
        let verseInfo = resolveAnsweringVerse(for: currentQuestion)

        feedbackResult = QuizFeedbackData(
            isCorrect: correct,
            title: correct ? "Correct!" : "Keep going! You're learning.",
            explain: currentQuestion.explain,
            correctChoice: correctChoiceText,
            verseRef: verseInfo.ref,
            verseText: verseInfo.text
        )
    }

    private func resolveAnsweringVerse(for question: QuizQuestion) -> (ref: String, text: String) {
        let correctText = question.choices[question.correctIndex]
        for ref in lesson.verseRefs {
            if let text = content.verse(ref: ref),
               text.localizedCaseInsensitiveContains(correctText) {
                return (ref, text)
            }
        }
        if let firstRef = lesson.verseRefs.first, let text = content.verse(ref: firstRef) {
            return (firstRef, text)
        }
        return ("Scripture", "In the beginning, God created the heavens and the earth.")
    }

    private func advanceToNextQuestion() {
        withAnimation(ShepherdTheme.morphSpring) {
            feedbackResult = nil
            isChecked = false
            selectedChoiceIndex = nil

            if questionIndex < lesson.quiz.count - 1 {
                questionIndex += 1
            } else {
                onFinished(totalScore)
            }
        }
    }
}

// MARK: - Quiz Feedback Sheet (Morph A End State)

struct QuizFeedbackSheet: View {
    let result: QuizView.QuizFeedbackData
    var onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Lamb Avatar + Title Header
            HStack(spacing: 12) {
                LambAvatarView(
                    stage: 1,
                    expression: result.isCorrect ? .happy : .encouraging,
                    size: 56
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(result.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(result.isCorrect ? ShepherdTheme.success : ShepherdTheme.error)

                    if !result.isCorrect {
                        Text("Answer: \(result.correctChoice).")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(ShepherdTheme.textSecondary)
                    }
                }
                Spacer()
            }

            // Explanation if present
            if let explain = result.explain, !explain.isEmpty {
                Text(explain)
                    .font(.system(size: 15))
                    .foregroundStyle(ShepherdTheme.textPrimary)
                    .lineSpacing(4)
            }

            // Answering Scripture Verse Card
            VerseCard(
                reference: result.verseRef,
                translation: "WEB",
                text: result.verseText
            )

            // Continue CTA Button
            ProminentGlassButton("Continue", action: onContinue)
                .padding(.top, 4)
        }
        .padding(20)
        .shepherdGlassCard(cornerRadius: 28)
        .padding(.horizontal, 12)
        .padding(.bottom, 16)
    }
}
