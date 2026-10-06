import Foundation

/// Display-time typography for lesson copy. The content JSON keeps straight quotes so the
/// validator can match quotations against WEB text; only what reaches the screen changes.
public enum LessonText {
    /// Straight `"` and `'` become typographic quotes: opening after the start, whitespace or an
    /// opening bracket, dash or quote; closing (or an apostrophe) everywhere else. Markdown `*`
    /// is looked through, so `**"Word"**` opens. Curly quotes already in the text are kept.
    public static func curlyQuotes(_ text: String) -> String {
        let opensAfter: Set<Character> = [" ", "\t", "\n", "(", "[", "{", "\u{2014}", "\u{2013}", "-", "/", "\u{201C}", "\u{2018}"]
        var out = ""
        out.reserveCapacity(text.count)
        var previous: Character? = nil
        for ch in text {
            let opening = previous.map { opensAfter.contains($0) } ?? true
            let shown: Character
            switch ch {
            case "\"": shown = opening ? "\u{201C}" : "\u{201D}"
            case "'": shown = opening ? "\u{2018}" : "\u{2019}"
            default: shown = ch
            }
            out.append(shown)
            if ch != "*" {
                previous = shown
            }
        }
        return out
    }

    public enum Block: Equatable {
        case paragraph(String)
        /// The body's `**Reflection:**` paragraph, without its label: the lesson screen draws
        /// the label as its own heading.
        case reflection(String)
    }

    static let reflectionLabel = "**Reflection:**"

    /// The body's paragraphs, in order, with the reflection paragraph marked.
    public static func blocks(fromBody markdown: String) -> [Block] {
        markdown.components(separatedBy: "\n\n").compactMap { raw in
            let paragraph = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !paragraph.isEmpty else { return nil }
            if paragraph.hasPrefix(reflectionLabel) {
                let question = paragraph.dropFirst(reflectionLabel.count).trimmingCharacters(in: .whitespaces)
                return .reflection(question)
            }
            return .paragraph(paragraph)
        }
    }
}

public extension Lesson {
    /// The title as shown on screen (typographic quotes).
    var displayTitle: String { LessonText.curlyQuotes(title) }
}
