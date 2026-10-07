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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public struct QuizFeedbackData: Equatable {
        public let isCorrect: Bool
        public let title: String
        public let explain: String?
        /// "Answer: …", shown after a wrong answer.
        public let answerLine: String
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

    /// A fill-in-the-blank shows its verse once, in the card, under a short lead-in.
    private var questionTitle: String {
        if currentQuestion.type == .fillBlank {
            return LessonText.curlyQuotes(QuizRules.fillBlankParts(currentQuestion.prompt).title)
        }
        return LessonText.curlyQuotes(currentQuestion.prompt)
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
                        Text(questionTitle)
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
            let verse = QuizRules.fillBlankParts(currentQuestion.prompt).verse
            let parts = verse.components(separatedBy: "___")
            VStack(alignment: .leading, spacing: 10) {
                if parts.count >= 2 {
                    Text("\u{201C}" + parts[0])
                        .font(ShepherdTheme.title3Serif())
                        .foregroundStyle(ShepherdTheme.textPrimary)
                    + Text(blankLabel)
                        .font(ShepherdTheme.title3Serif().weight(.bold))
                        .foregroundColor(blankTextColor)
                    + Text(parts[1] + "\u{201D}")
                        .font(ShepherdTheme.title3Serif())
                        .foregroundStyle(ShepherdTheme.textPrimary)
                } else {
                    Text(LessonText.curlyQuotes(verse))
                        .font(ShepherdTheme.title3Serif())
                        .foregroundStyle(ShepherdTheme.textPrimary)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(verse.replacingOccurrences(of: "___", with: blankSpokenWord))
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
                                            .font(.caption2.weight(.bold))
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
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(chipTextColor(state: state))

                        Text(label)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(chipTextColor(state: state))

                        Spacer()

                        if isSelected && !isChecked {
                            Circle()
                                .strokeBorder(ShepherdTheme.accent, lineWidth: 2)
                                .frame(width: 24, height: 24)
                                .accessibilityHidden(true)
                        } else if state == .correct || state == .revealed {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(ShepherdTheme.success)
                        } else if state == .wrong {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
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
            // Side by side normally; at accessibility text sizes the columns stack, so words
            // are never broken across lines and each card keeps its full width.
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 18))
                : AnyLayout(HStackLayout(alignment: .top, spacing: 12))

            layout {
                VStack(spacing: 10) {
                    ForEach(Array(pairs.enumerated()), id: \.element.ref) { index, pair in
                        matchReferenceCard(pair, number: index + 1, pairs: pairs)
                    }
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 10) {
                    ForEach(QuizRules.matchDisplayOrder(for: currentQuestion), id: \.self) { idx in
                        matchVerseCard(pairs[idx], pairs: pairs)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    /// The state of one card in a match question, before and after Check.
    private enum MatchCardState { case open, selected, matched, correct, wrong }

    private func matchState(isMatched: Bool, isSelected: Bool, isRight: Bool) -> MatchCardState {
        if isChecked && isMatched { return isRight ? .correct : .wrong }
        if isMatched { return .matched }
        return isSelected ? .selected : .open
    }

    /// Each reference keeps a number; the verse it is matched to shows the same number, so the
    /// pairing is visible before Check (and spoken: "matched to …").
    private func matchReferenceCard(_ pair: MatchPair, number: Int, pairs: [MatchPair]) -> some View {
        let display = ContentStore.displayRef(pair.ref)
        let matchedText = matchedPairs[pair.ref].flatMap { target in pairs.first { $0.ref == target }?.text }
        let state = matchState(isMatched: matchedText != nil, isSelected: selectedMatchRef == pair.ref,
                               isRight: matchedPairs[pair.ref] == pair.ref)
        let spokenState: String = {
            switch state {
            case .open: return "tap to select"
            case .selected: return "selected"
            case .matched: return "matched to: \(matchedText ?? "")"
            case .correct: return "correctly matched to: \(matchedText ?? "")"
            case .wrong: return "incorrectly matched to: \(matchedText ?? "")"
            }
        }()

        return Button {
            guard !isChecked else { return }
            if matchedPairs[pair.ref] != nil {
                matchedPairs.removeValue(forKey: pair.ref)
            } else {
                selectedMatchRef = (selectedMatchRef == pair.ref ? nil : pair.ref)
            }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                matchBadge(number, state: state)
                Text(display)
                    .font(.callout.weight(.bold))
                    .foregroundStyle(ShepherdTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .frame(minHeight: 76)
            .background(matchBackground(state))
            .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD)
                    .stroke(matchBorder(state), lineWidth: state == .open ? 1 : 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Reference \(display), \(spokenState)")
    }

    private func matchVerseCard(_ pair: MatchPair, pairs: [MatchPair]) -> some View {
        let matchedRef = matchedPairs.first(where: { $0.value == pair.ref })?.key
        let number = matchedRef.flatMap { ref in pairs.firstIndex { $0.ref == ref } }.map { $0 + 1 }
        let state = matchState(isMatched: matchedRef != nil, isSelected: false, isRight: matchedRef == pair.ref)
        let spokenState: String = {
            guard let matchedRef else { return "tap to match" }
            let display = ContentStore.displayRef(matchedRef)
            switch state {
            case .correct: return "correctly matched to \(display)"
            case .wrong: return "incorrectly matched to \(display)"
            default: return "matched to \(display)"
            }
        }()

        return Button {
            guard !isChecked else { return }
            if let existing = matchedRef {
                matchedPairs.removeValue(forKey: existing)
            } else if let activeRef = selectedMatchRef {
                matchedPairs[activeRef] = pair.ref
                selectedMatchRef = nil
            }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                if let number {
                    matchBadge(number, state: state)
                }
                Text(pair.text)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(ShepherdTheme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .frame(minHeight: 76)
            .background(matchBackground(state == .selected ? .open : state))
            .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD)
                    .stroke(matchBorder(state), lineWidth: state == .open ? 1 : 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Verse: \(pair.text), \(spokenState)")
    }

    private func matchBadge(_ number: Int, state: MatchCardState) -> some View {
        let tint: Color = {
            switch state {
            case .correct: return ShepherdTheme.success
            case .wrong: return ShepherdTheme.error
            default: return ShepherdTheme.accent
            }
        }()
        return Text("\(number)")
            .font(.caption.weight(.bold).monospacedDigit())
            .foregroundStyle(tint)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .overlay(Capsule().stroke(tint, lineWidth: 1.5))
            .accessibilityHidden(true)
    }

    private func matchBackground(_ state: MatchCardState) -> Color {
        switch state {
        case .open: return ShepherdTheme.cardSurface
        case .selected: return ShepherdTheme.accentSubtle
        case .matched: return ShepherdTheme.surfaceSunken
        case .correct: return ShepherdTheme.successSubtle
        case .wrong: return ShepherdTheme.errorSubtle
        }
    }

    private func matchBorder(_ state: MatchCardState) -> Color {
        switch state {
        case .open: return ShepherdTheme.surfaceBorder
        case .selected: return ShepherdTheme.accent
        case .matched: return ShepherdTheme.accentFill
        case .correct: return ShepherdTheme.success
        case .wrong: return ShepherdTheme.error
        }
    }

    // MARK: - Style Helpers

    private var blankLabel: String {
        if let idx = selectedChoiceIndex, currentQuestion.choices.indices.contains(idx) {
            return "[\(currentQuestion.choices[idx])]"
        }
        return "[ ___ ]"
    }

    /// VoiceOver reads the slot as "blank" (not punctuation) until a word fills it.
    private var blankSpokenWord: String {
        if let idx = selectedChoiceIndex, currentQuestion.choices.indices.contains(idx) {
            return currentQuestion.choices[idx]
        }
        return "blank"
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

        switch currentQuestion.type {
        case .choice, .fillBlank, .trueFalse:
            correct = (selectedChoiceIndex ?? -1) == currentQuestion.correctIndex
        case .order:
            let expected = currentQuestion.orderTokens ?? []
            correct = placedTokenIndices.map { expected[$0] } == expected
        case .match:
            correct = (currentQuestion.pairs ?? []).allSatisfy { matchedPairs[$0.ref] == $0.ref }
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
            answerLine: QuizRules.answerLine(LessonText.curlyQuotes(QuizRules.answerText(for: currentQuestion))),
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
            let size = subview.sizeThatFits(ProposedViewSize(width: width.isFinite ? width : nil, height: nil))
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
            let size = subview.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
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
                Text(result.answerLine)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(ShepherdTheme.textSecondary)
                    .accessibilityLabel(result.answerLine.replacingOccurrences(of: " → ", with: " matches: "))
            }
        }
    }
}
