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
    @State private var placedTokenIndices: [Int] = []
    @State private var selectedMatchRef: String? = nil
    @State private var matchedPairs: [String: String] = [:]
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
        public let verseRef: String?
        public let verseText: String?
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

    private var canCheck: Bool {
        switch currentQuestion.type {
        case .choice, .fillBlank, .trueFalse:
            return selectedChoiceIndex != nil
        case .order:
            let total = currentQuestion.orderTokens?.count ?? 0
            return total > 0 && placedTokenIndices.count == total
        case .match:
            let total = currentQuestion.pairs?.count ?? 0
            return total > 0 && matchedPairs.count == total
        }
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
                        Text(LessonText.curlyQuotes(currentQuestion.prompt))
                            .font(ShepherdTheme.title2Serif())
                            .foregroundStyle(ShepherdTheme.textPrimary)
                            .padding(.top, 4)

                        // Exercise content by type
                        switch currentQuestion.type {
                        case .choice:
                            choiceExerciseView
                        case .fillBlank:
                            fillBlankExerciseView
                        case .order:
                            orderExerciseView
                        case .trueFalse:
                            trueFalseExerciseView
                        case .match:
                            matchExerciseView
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
                        .disabled(!canCheck)
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

    // MARK: - Exercise Views

    @ViewBuilder
    private var choiceExerciseView: some View {
        VStack(spacing: 12) {
            let letters = ["A", "B", "C", "D"]
            ForEach(Array(QuizRules.displayOrder(for: currentQuestion).enumerated()), id: \.element) { position, i in
                let choice = currentQuestion.choices[i]
                let letter = position < letters.count ? letters[position] : "\(position + 1)"
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

                ChoiceRow(letter: letter, text: LessonText.curlyQuotes(choice), state: state) {
                    if !isChecked {
                        selectedChoiceIndex = i
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var fillBlankExerciseView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Verse card highlighting the fillable slot
            let parts = currentQuestion.prompt.components(separatedBy: "___")
            VStack(alignment: .leading, spacing: 10) {
                if parts.count >= 2 {
                    Text(parts[0])
                        .font(ShepherdTheme.title3Serif())
                        .foregroundStyle(ShepherdTheme.textPrimary)
                    + Text(blankLabel)
                        .font(ShepherdTheme.title3Serif().weight(.bold))
                        .foregroundColor(blankTextColor)
                    + Text(parts[1])
                        .font(ShepherdTheme.title3Serif())
                        .foregroundStyle(ShepherdTheme.textPrimary)
                } else {
                    Text(currentQuestion.prompt)
                        .font(ShepherdTheme.title3Serif())
                        .foregroundStyle(ShepherdTheme.textPrimary)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(blankCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusLG))
            .overlay(
                RoundedRectangle(cornerRadius: ShepherdTheme.radiusLG)
                    .stroke(blankCardBorder, lineWidth: 1.5)
            )

            Text("Select the missing word:")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ShepherdTheme.textSecondary)
                .padding(.top, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Array(QuizRules.displayOrder(for: currentQuestion).enumerated()), id: \.element) { position, i in
                    let choice = currentQuestion.choices[i]
                    let isSelected = selectedChoiceIndex == i
                    let chipState: ChoiceRowState = {
                        if !isChecked {
                            return isSelected ? .selected : .neutral
                        }
                        if i == currentQuestion.correctIndex {
                            return isAnswerCorrect ? .correct : .revealed
                        }
                        if isSelected {
                            return .wrong
                        }
                        return .neutral
                    }()

                    Button {
                        if !isChecked {
                            selectedChoiceIndex = i
                        }
                    } label: {
                        Text(choice)
                            .font(.body.weight(.medium))
                            .foregroundStyle(chipTextColor(state: chipState))
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 52)
                            .padding(.horizontal, 12)
                            .background(chipBgColor(state: chipState))
                            .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
                            .overlay(
                                RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD)
                                    .stroke(chipBorderColor(state: chipState), lineWidth: chipState == .neutral ? 1 : 2)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Word option: \(choice)")
                    .accessibilityHint("Fills the missing word in the verse")
                }
            }
        }
    }

    @ViewBuilder
    private var orderExerciseView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Tap words in order:")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ShepherdTheme.textSecondary)

                Spacer()

                if !placedTokenIndices.isEmpty && !isChecked {
                    Button {
                        placedTokenIndices.removeAll()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset")
                        }
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(ShepherdTheme.accent)
                    }
                    .accessibilityLabel("Reset words")
                }
            }

            // Answer Line / Placed tokens
            VStack(alignment: .leading, spacing: 8) {
                if placedTokenIndices.isEmpty {
                    Text("Tap words below in the correct order")
                        .font(.body)
                        .foregroundStyle(ShepherdTheme.textTertiary)
                        .frame(maxWidth: .infinity, minHeight: 80, alignment: .center)
                } else {
                    FlowLayout(spacing: 8) {
                        let tokens = currentQuestion.orderTokens ?? []
                        ForEach(Array(placedTokenIndices.enumerated()), id: \.offset) { index, tokenIndex in
                            let token = tokens[tokenIndex]
                            Button {
                                if !isChecked {
                                    placedTokenIndices.remove(at: index)
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(token)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(ShepherdTheme.textPrimary)
                                    if !isChecked {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(ShepherdTheme.textTertiary)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(orderPlacedBgColor)
                                .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
                                .overlay(
                                    RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD)
                                        .stroke(orderPlacedBorderColor, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Placed word \(index + 1): \(token). Tap to remove.")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 90)
            .background(ShepherdTheme.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusLG))
            .overlay(
                RoundedRectangle(cornerRadius: ShepherdTheme.radiusLG)
                    .stroke(orderCardBorderColor, lineWidth: 1.5)
            )

            // Word bank
            let tokens = currentQuestion.orderTokens ?? []
            let bankIndices = QuizRules.tokenDisplayOrder(for: currentQuestion).filter { !placedTokenIndices.contains($0) }

            if !bankIndices.isEmpty {
                Text("Word bank:")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ShepherdTheme.textSecondary)
                    .padding(.top, 8)

                FlowLayout(spacing: 8) {
                    ForEach(bankIndices, id: \.self) { tokenIndex in
                        let token = tokens[tokenIndex]
                        Button {
                            if !isChecked {
                                placedTokenIndices.append(tokenIndex)
                            }
                        } label: {
                            Text(token)
                                .font(.body.weight(.medium))
                                .foregroundStyle(ShepherdTheme.textPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(ShepherdTheme.surfaceSunken)
                                .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
                                .overlay(
                                    RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD)
                                        .stroke(ShepherdTheme.surfaceBorder, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Available word: \(token). Tap to add to answer.")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var trueFalseExerciseView: some View {
        VStack(spacing: 14) {
            let options: [(String, String, Int)] = [("True", "checkmark.circle.fill", 0), ("False", "xmark.circle.fill", 1)]
            ForEach(options, id: \.2) { label, icon, index in
                let isSelected = selectedChoiceIndex == index
                let state: ChoiceRowState = {
                    if !isChecked {
                        return isSelected ? .selected : .neutral
                    }
                    if index == currentQuestion.correctIndex {
                        return isAnswerCorrect ? .correct : .revealed
                    }
                    if isSelected {
                        return .wrong
                    }
                    return .neutral
                }()

                Button {
                    if !isChecked {
                        selectedChoiceIndex = index
                    }
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: icon)
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(chipTextColor(state: state))

                        Text(label)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(chipTextColor(state: state))

                        Spacer()

                        if isSelected && !isChecked {
                            Circle()
                                .strokeBorder(ShepherdTheme.accent, lineWidth: 2)
                                .frame(width: 24, height: 24)
                        } else if state == .correct || state == .revealed {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(ShepherdTheme.success)
                        } else if state == .wrong {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(ShepherdTheme.error)
                        }
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 68)
                    .background(chipBgColor(state: state))
                    .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
                    .overlay(
                        RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD)
                            .stroke(chipBorderColor(state: state), lineWidth: state == .neutral ? 1 : 2)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(label), \(isSelected ? "selected" : "unselected")")
            }
        }
    }

    @ViewBuilder
    private var matchExerciseView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Tap a reference, then tap its matching verse:")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ShepherdTheme.textSecondary)

            let pairs = currentQuestion.pairs ?? []
            let shuffledIndices = QuizRules.matchDisplayOrder(for: currentQuestion)

            HStack(alignment: .top, spacing: 12) {
                // Left Column: References
                VStack(spacing: 10) {
                    ForEach(pairs, id: \.ref) { pair in
                        let isSelected = selectedMatchRef == pair.ref
                        let isMatched = matchedPairs[pair.ref] != nil
                        let isPairCorrect = isChecked && matchedPairs[pair.ref] == pair.ref
                        let isPairWrong = isChecked && isMatched && matchedPairs[pair.ref] != pair.ref

                        Button {
                            if !isChecked {
                                if isMatched {
                                    matchedPairs.removeValue(forKey: pair.ref)
                                } else {
                                    selectedMatchRef = (selectedMatchRef == pair.ref ? nil : pair.ref)
                                }
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ContentStore.displayRef(pair.ref))
                                    .font(.callout.weight(.bold))
                                    .foregroundStyle(ShepherdTheme.textPrimary)

                                if isMatched {
                                    Text("Matched")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(isPairCorrect ? ShepherdTheme.success : (isPairWrong ? ShepherdTheme.error : ShepherdTheme.accent))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .frame(minHeight: 76)
                            .background(
                                isPairCorrect ? ShepherdTheme.successSubtle :
                                (isPairWrong ? ShepherdTheme.errorSubtle :
                                (isSelected ? ShepherdTheme.accentSubtle :
                                (isMatched ? ShepherdTheme.surfaceSunken : ShepherdTheme.cardSurface)))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
                            .overlay(
                                RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD)
                                    .stroke(
                                        isPairCorrect ? ShepherdTheme.success :
                                        (isPairWrong ? ShepherdTheme.error :
                                        (isSelected ? ShepherdTheme.accent :
                                        (isMatched ? ShepherdTheme.accentFill : ShepherdTheme.surfaceBorder))),
                                        lineWidth: (isSelected || isMatched || isChecked) ? 2 : 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Reference \(ContentStore.displayRef(pair.ref)), \(isMatched ? "matched" : isSelected ? "selected" : "tap to select")")
                    }
                }
                .frame(maxWidth: .infinity)

                // Right Column: Verses
                VStack(spacing: 10) {
                    ForEach(shuffledIndices, id: \.self) { idx in
                        let pair = pairs[idx]
                        let matchedRef = matchedPairs.first(where: { $0.value == pair.ref })?.key
                        let isMatched = matchedRef != nil
                        let isPairCorrect = isChecked && matchedRef == pair.ref
                        let isPairWrong = isChecked && isMatched && matchedRef != pair.ref

                        Button {
                            if !isChecked {
                                if let existing = matchedRef {
                                    matchedPairs.removeValue(forKey: existing)
                                } else if let activeRef = selectedMatchRef {
                                    matchedPairs[activeRef] = pair.ref
                                    selectedMatchRef = nil
                                }
                            }
                        } label: {
                            Text(pair.text)
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(ShepherdTheme.textPrimary)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .frame(minHeight: 76)
                                .background(
                                    isPairCorrect ? ShepherdTheme.successSubtle :
                                    (isPairWrong ? ShepherdTheme.errorSubtle :
                                    (isMatched ? ShepherdTheme.surfaceSunken : ShepherdTheme.cardSurface))
                                )
                                .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
                                .overlay(
                                    RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD)
                                        .stroke(
                                            isPairCorrect ? ShepherdTheme.success :
                                            (isPairWrong ? ShepherdTheme.error :
                                            (isMatched ? ShepherdTheme.accentFill : ShepherdTheme.surfaceBorder)),
                                            lineWidth: (isMatched || isChecked) ? 2 : 1
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Verse: \(pair.text), \(isMatched ? "matched" : "tap to match")")
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Style Helpers

    private var blankLabel: String {
        if let idx = selectedChoiceIndex, currentQuestion.choices.indices.contains(idx) {
            return " [\(currentQuestion.choices[idx])] "
        }
        return " [ ___ ] "
    }

    private var blankTextColor: Color {
        if !isChecked {
            return selectedChoiceIndex != nil ? ShepherdTheme.accent : ShepherdTheme.textTertiary
        }
        return isAnswerCorrect ? ShepherdTheme.success : ShepherdTheme.error
    }

    private var blankCardBackground: Color {
        if !isChecked { return ShepherdTheme.cardSurface }
        return isAnswerCorrect ? ShepherdTheme.successSubtle : ShepherdTheme.errorSubtle
    }

    private var blankCardBorder: Color {
        if !isChecked {
            return selectedChoiceIndex != nil ? ShepherdTheme.accent : ShepherdTheme.surfaceBorder
        }
        return isAnswerCorrect ? ShepherdTheme.success : ShepherdTheme.error
    }

    private func chipBgColor(state: ChoiceRowState) -> Color {
        switch state {
        case .neutral: return ShepherdTheme.cardSurface
        case .selected: return ShepherdTheme.accentSubtle
        case .correct, .revealed: return ShepherdTheme.successSubtle
        case .wrong: return ShepherdTheme.errorSubtle
        }
    }

    private func chipBorderColor(state: ChoiceRowState) -> Color {
        switch state {
        case .neutral: return ShepherdTheme.surfaceBorder
        case .selected: return ShepherdTheme.accent
        case .correct, .revealed: return ShepherdTheme.success
        case .wrong: return ShepherdTheme.error
        }
    }

    private func chipTextColor(state: ChoiceRowState) -> Color {
        switch state {
        case .neutral: return ShepherdTheme.textPrimary
        case .selected: return ShepherdTheme.accent
        case .correct, .revealed: return ShepherdTheme.success
        case .wrong: return ShepherdTheme.error
        }
    }

    private var orderPlacedBgColor: Color {
        if !isChecked { return ShepherdTheme.accentSubtle }
        return isAnswerCorrect ? ShepherdTheme.successSubtle : ShepherdTheme.errorSubtle
    }

    private var orderPlacedBorderColor: Color {
        if !isChecked { return ShepherdTheme.accent }
        return isAnswerCorrect ? ShepherdTheme.success : ShepherdTheme.error
    }

    private var orderCardBorderColor: Color {
        if !isChecked {
            return placedTokenIndices.isEmpty ? ShepherdTheme.surfaceBorder : ShepherdTheme.accent
        }
        return isAnswerCorrect ? ShepherdTheme.success : ShepherdTheme.error
    }

    // MARK: - Grading and Navigation

    private func evaluateAnswer() {
        guard canCheck else { return }
        isChecked = true
        let correct: Bool
        let correctChoiceText: String

        switch currentQuestion.type {
        case .choice, .fillBlank:
            let selected = selectedChoiceIndex ?? -1
            correct = (selected == currentQuestion.correctIndex)
            correctChoiceText = currentQuestion.choices.indices.contains(currentQuestion.correctIndex)
                ? currentQuestion.choices[currentQuestion.correctIndex]
                : ""
        case .trueFalse:
            let selected = selectedChoiceIndex ?? -1
            correct = (selected == currentQuestion.correctIndex)
            correctChoiceText = currentQuestion.correctIndex == 0 ? "True" : "False"
        case .order:
            let expected = currentQuestion.orderTokens ?? []
            let actual = placedTokenIndices.map { expected[$0] }
            correct = (actual == expected)
            correctChoiceText = expected.joined(separator: " ")
        case .match:
            let pairs = currentQuestion.pairs ?? []
            correct = pairs.allSatisfy { matchedPairs[$0.ref] == $0.ref }
            correctChoiceText = "All references matched"
        }

        isAnswerCorrect = correct
        if correct {
            totalScore += 1
        }
        answeredCount += 1

        let verseInfo = QuizRules.answeringVerse(for: currentQuestion, in: lesson, verses: { content.verse(ref: $0) })

        feedbackResult = QuizFeedbackData(
            isCorrect: correct,
            title: correct ? "Correct!" : "Keep going! You’re learning.",
            explain: currentQuestion.explain.map(LessonText.curlyQuotes),
            correctChoice: LessonText.curlyQuotes(correctChoiceText),
            verseRef: verseInfo?.ref,
            verseText: verseInfo?.text
        )
    }

    private func advanceToNextQuestion() {
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : ShepherdTheme.morphSpring) {
            feedbackResult = nil
            isChecked = false
            selectedChoiceIndex = nil
            placedTokenIndices = []
            selectedMatchRef = nil
            matchedPairs = [:]

            if questionIndex < lesson.quiz.count - 1 {
                questionIndex += 1
            } else {
                onFinished(totalScore)
            }
        }
    }
}

// MARK: - FlowLayout Component

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: width, height: currentY + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX, currentX > bounds.minX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
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
                if let ref = result.verseRef, let text = result.verseText {
                    VerseCard(
                        reference: ref,
                        translation: "WEB",
                        text: text
                    )
                }

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
