import Foundation

public enum QuizRules {
    /// The verse shown as proof after a question is checked: the question's `answerRef`, else the
    /// first lesson verse that contains the correct choice (typographic quotes normalised).
    /// Returns nil rather than an unrelated verse; content validation makes that case an error.
    public static func answeringVerse(
        for question: QuizQuestion,
        in lesson: Lesson,
        verses: (String) -> String?
    ) -> (ref: String, text: String)? {
        if let ref = question.answerRef, let text = verses(ref) {
            return (ref, text)
        }
        guard question.choices.indices.contains(question.correctIndex) else { return nil }
        let correctText = normalizedQuotes(question.choices[question.correctIndex])
        for ref in lesson.verseRefs {
            if let text = verses(ref),
               normalizedQuotes(text).localizedCaseInsensitiveContains(correctText) {
                return (ref, text)
            }
        }
        return nil
    }

    public static func normalizedQuotes(_ s: String) -> String {
        s.replacingOccurrences(of: "\u{2019}", with: "'")
            .replacingOccurrences(of: "\u{2018}", with: "'")
            .replacingOccurrences(of: "\u{201C}", with: "\"")
            .replacingOccurrences(of: "\u{201D}", with: "\"")
    }

    /// The order to display a question's choices in: a permutation of its indices, seeded only by
    /// the question id. It is the same on every launch and device (no `hashValue`, which Swift
    /// randomises per process), and it does not depend on `correctIndex`, so the position of the
    /// answer on screen tells the reader nothing. For `.trueFalse`, choices remain in authored order [0, 1].
    public static func displayOrder(for question: QuizQuestion) -> [Int] {
        if question.type == .trueFalse {
            return Array(question.choices.indices)
        }
        var order = Array(question.choices.indices)
        var rng = SplitMix64(seed: fnv1a(question.id))
        if order.count > 1 {
            for i in stride(from: order.count - 1, to: 0, by: -1) {
                let j = Int(rng.next() % UInt64(i + 1))
                order.swapAt(i, j)
            }
        }
        return order
    }

    /// The order to display available tokens in an `order` question word bank: seeded by question id.
    public static func tokenDisplayOrder(for question: QuizQuestion) -> [Int] {
        guard let tokens = question.orderTokens, !tokens.isEmpty else { return [] }
        var order = Array(tokens.indices)
        var rng = SplitMix64(seed: fnv1a(question.id + "-tokens"))
        if order.count > 1 {
            for i in stride(from: order.count - 1, to: 0, by: -1) {
                let j = Int(rng.next() % UInt64(i + 1))
                order.swapAt(i, j)
            }
            if order == Array(tokens.indices) {
                let first = order.removeFirst()
                order.append(first)
            }
        }
        return order
    }

    /// The order to display right-side matches in a `match` question: seeded by question id.
    public static func matchDisplayOrder(for question: QuizQuestion) -> [Int] {
        guard let pairs = question.pairs, !pairs.isEmpty else { return [] }
        var order = Array(pairs.indices)
        var rng = SplitMix64(seed: fnv1a(question.id + "-pairs"))
        if order.count > 1 {
            for i in stride(from: order.count - 1, to: 0, by: -1) {
                let j = Int(rng.next() % UInt64(i + 1))
                order.swapAt(i, j)
            }
            if order == Array(pairs.indices) {
                let first = order.removeFirst()
                order.append(first)
            }
        }
        return order
    }

    static func fnv1a(_ s: String) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in s.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return hash
    }

    struct SplitMix64 {
        var state: UInt64
        init(seed: UInt64) { state = seed }
        mutating func next() -> UInt64 {
            state = state &+ 0x9e37_79b9_7f4a_7c15
            var z = state
            z = (z ^ (z >> 30)) &* 0xbf58_476d_1ce4_e5b9
            z = (z ^ (z >> 27)) &* 0x94d0_49bb_1331_11eb
            return z ^ (z >> 31)
        }
    }
}
