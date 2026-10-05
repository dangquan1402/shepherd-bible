import SwiftUI
import SwiftData

public struct QuizView: View {
    public let lesson: Lesson
    public var onFinished: (Int) -> Void

    @EnvironmentObject private var content: ContentStore
    @Environment(\.dismiss) private var dismiss
    @Query private var companions: [Companion]

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

    private var companionStage: Int {
        companions.first?.stage ?? 1
    }

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ShepherdTheme.canvasBg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Eyebrow
                        Text("DAY \(lesson.dayIndex)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(ShepherdTheme.accent)
                            .padding(.top, 12)

                        // Question Prompt
                        Text(currentQuestion.prompt)
                            .font(ShepherdTheme.title2Serif())
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
                    ShepherdTheme.scrimSoft
                        .ignoresSafeArea()
                        .transition(.opacity)
                }

                // Morph A: GlassEffectContainer morphing Check button into FeedbackSheet
                GlassEffectContainer(spacing: 16) {
                    if let result = feedbackResult {
                        QuizFeedbackSheet(
                            result: result,
                            companionStage: companionStage
                        ) {
                            advanceToNextQuestion()
                        }
                        .glassEffectID("quiz_action", in: morphNamespace)
                        .transition(reduceMotion ? .opacity : .identity)
                    } else {
                        Button {
                            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : ShepherdTheme.morphSpring) {
                                evaluateAnswer()
                            }
                        } label: {
                            Text("Check")
                                .font(.body.weight(.bold))
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 56)
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .accessibilityLabel("Close Quiz")
                }

                ToolbarItem(placement: .principal) {
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
                    .frame(width: 180, height: 6)
                }
            }
            .sensoryFeedback(trigger: feedbackResult) { _, new in
                guard let new else { return nil }
                return new.isCorrect ? .success : .warning
            }
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

        let correctChoiceText = currentQuestion.choices[currentQuestion.correctIndex]
        let verseInfo = QuizRules.answeringVerse(for: currentQuestion, in: lesson, verses: { content.verse(ref: $0) })

        feedbackResult = QuizFeedbackData(
            isCorrect: correct,
            title: correct ? "Correct!" : "Keep going! You're learning.",
            explain: currentQuestion.explain,
            correctChoice: correctChoiceText,
            verseRef: verseInfo.ref,
            verseText: verseInfo.text
        )
    }

    private func advanceToNextQuestion() {
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : ShepherdTheme.morphSpring) {
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
    let companionStage: Int
    var onContinue: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var animTick = 0
    @State private var tilted = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Mascot Avatar + Title Header (Row 3 hop on correct, Row 4 tilt on wrong)
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 12) {
                        avatarView
                        titleView
                    }
                } else {
                    HStack(spacing: 12) {
                        avatarView
                        titleView
                        Spacer()
                    }
                }

                // Explanation if present
                if let explain = result.explain, !explain.isEmpty {
                    Text(explain)
                        .font(.callout)
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
        }
        .frame(maxHeight: 520)
        .shepherdGlassCard(cornerRadius: 28)
        .padding(.horizontal, 12)
        .padding(.bottom, 16)
        .onAppear {
            guard !reduceMotion else { return }
            animTick += 1
            if !result.isCorrect {
                withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
                    tilted = true
                }
            }
        }
    }

    private var avatarView: some View {
        AnimatedLambView(
            stage: companionStage,
            expression: result.isCorrect ? .happy : .encouraging,
            displayHeight: 56,
            isBreathing: false,
            hopTrigger: result.isCorrect ? animTick : 0,
            isTilted: tilted
        )
        .frame(width: 56, height: 56)
        .clipShape(Circle())
    }

    private var titleView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(result.title)
                .font(ShepherdTheme.title2Serif())
                .foregroundStyle(result.isCorrect ? ShepherdTheme.success : ShepherdTheme.error)

            if !result.isCorrect {
                Text("Answer: \(result.correctChoice).")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(ShepherdTheme.textSecondary)
            }
        }
    }
}
