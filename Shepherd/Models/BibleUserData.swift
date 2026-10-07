import Foundation
import SwiftUI
import SwiftData

// MARK: - Highlight Color Enum

public enum BibleHighlightColor: String, CaseIterable, Identifiable, Codable {
    case yellow
    case blue
    case purple
    case rose
    case amber

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .yellow: return "Yellow"
        case .blue: return "Blue"
        case .purple: return "Purple"
        case .rose: return "Rose"
        case .amber: return "Amber"
        }
    }

    public var colorName: String {
        switch self {
        case .yellow: return "HighlightYellow"
        case .blue: return "HighlightBlue"
        case .purple: return "HighlightPurple"
        case .rose: return "HighlightRose"
        case .amber: return "HighlightAmber"
        }
    }

    public var color: Color {
        Color(colorName)
    }

    /// The dot on the colour's swatch button, which names the colour (the fills alone are too close
    /// to each other in dark mode).
    public var swatchColor: Color {
        Color(colorName + "Swatch")
    }
}

// MARK: - Verse Selection

/// The reader's verse selection. Always one contiguous run, so the verses drawn as selected are
/// exactly the verses that get highlighted, bookmarked, noted, copied and shared.
public struct VerseSelection: Equatable {
    public private(set) var range: ClosedRange<Int>?

    public init(range: ClosedRange<Int>? = nil) {
        self.range = range
    }

    public var isEmpty: Bool { range == nil }

    public var verses: [Int] { range.map(Array.init) ?? [] }

    public func contains(_ verse: Int) -> Bool {
        range?.contains(verse) ?? false
    }

    /// Tapping outside the run extends it to the tapped verse (verses in between join the run).
    /// Tapping a verse inside the run deselects it and every verse after it.
    public mutating func tap(_ verse: Int) {
        guard let current = range else {
            range = verse...verse
            return
        }
        if verse < current.lowerBound {
            range = verse...current.upperBound
        } else if verse > current.upperBound {
            range = current.lowerBound...verse
        } else if verse == current.lowerBound {
            range = verse < current.upperBound ? (verse + 1)...current.upperBound : nil
        } else {
            range = current.lowerBound...(verse - 1)
        }
    }

    public mutating func clear() {
        range = nil
    }
}

// MARK: - Formatted Scripture Helper

public enum BibleFormatter {
    /// Formats scripture for copying and sharing: text + reference + "World English Bible" attribution.
    /// The reference is built from the same verses as the text, so the two cannot disagree.
    public static func formattedText(bookName: String, chapter: Int, verses: [BibleVerse]) -> String {
        let combinedText = verses.map(\.text).joined(separator: " ")
        let reference = referenceString(bookName: bookName, chapter: chapter, verses: verses.map(\.number))
        return """
        \(combinedText)

        \(reference)
        World English Bible
        """
    }

    public static func referenceString(
        bookName: String,
        chapter: Int,
        startVerse: Int,
        endVerse: Int
    ) -> String {
        referenceString(bookName: bookName, chapter: chapter, verses: Array(min(startVerse, endVerse)...max(startVerse, endVerse)))
    }

    /// "Genesis 1:1–3", or one part per contiguous run: "Genesis 1:1, 3" and "Genesis 1:1–3, 5".
    public static func referenceString(bookName: String, chapter: Int, verses: [Int]) -> String {
        let runs = verseRuns(verses).map { run in
            run.lowerBound == run.upperBound ? "\(run.lowerBound)" : "\(run.lowerBound)–\(run.upperBound)"
        }
        return "\(bookName) \(chapter):\(runs.joined(separator: ", "))"
    }

    /// Sorted, de-duplicated verse numbers grouped into contiguous runs.
    public static func verseRuns(_ verses: [Int]) -> [ClosedRange<Int>] {
        var runs: [ClosedRange<Int>] = []
        for verse in Set(verses).sorted() {
            if let last = runs.last, last.upperBound + 1 == verse {
                runs[runs.count - 1] = last.lowerBound...verse
            } else {
                runs.append(verse...verse)
            }
        }
        return runs
    }
}

// MARK: - Range Editing

/// A saved verse range (a highlight or a bookmark) as a plain value, so range edits can be computed
/// and tested without SwiftData.
public struct VerseSpan<Value: Equatable>: Equatable {
    public var range: ClosedRange<Int>
    public var value: Value

    public init(_ range: ClosedRange<Int>, _ value: Value) {
        self.range = range
        self.value = value
    }
}

public enum BibleRangeEditor {
    /// Removes `cut` from every span. A span that only partly overlaps keeps the verses outside
    /// `cut`, split in two when `cut` falls in its middle, with its own value.
    public static func removing<V>(_ cut: ClosedRange<Int>, from spans: [VerseSpan<V>]) -> [VerseSpan<V>] {
        spans.flatMap { span -> [VerseSpan<V>] in
            guard span.range.overlaps(cut) else { return [span] }
            var pieces: [VerseSpan<V>] = []
            if span.range.lowerBound < cut.lowerBound {
                pieces.append(VerseSpan(span.range.lowerBound...(cut.lowerBound - 1), span.value))
            }
            if span.range.upperBound > cut.upperBound {
                pieces.append(VerseSpan((cut.upperBound + 1)...span.range.upperBound, span.value))
            }
            return pieces
        }
    }

    /// Puts `new` over the spans: what it covers takes its value, everything else is unchanged.
    public static func applying<V>(_ new: VerseSpan<V>, to spans: [VerseSpan<V>]) -> [VerseSpan<V>] {
        (removing(new.range, from: spans) + [new]).sorted { $0.range.lowerBound < $1.range.lowerBound }
    }
}

// MARK: - SwiftData Models

@Model
public final class BibleHighlight {
    @Attribute(.unique) public var id: String
    public var book: String          // e.g. "GEN"
    public var chapter: Int          // e.g. 1
    public var startVerse: Int      // e.g. 1
    public var endVerse: Int        // e.g. 3
    public var colorName: String    // e.g. "yellow"
    public var createdAt: Date
    public var verseText: String

    public init(
        id: String = UUID().uuidString,
        book: String,
        chapter: Int,
        startVerse: Int,
        endVerse: Int? = nil,
        colorName: String = "yellow",
        createdAt: Date = .now,
        verseText: String = ""
    ) {
        self.id = id
        self.book = book
        self.chapter = chapter
        let end = endVerse ?? startVerse
        self.startVerse = min(startVerse, end)
        self.endVerse = max(startVerse, end)
        self.colorName = colorName
        self.createdAt = createdAt
        self.verseText = verseText
    }

    public var highlightColor: BibleHighlightColor {
        BibleHighlightColor(rawValue: colorName) ?? .yellow
    }

    public func contains(verse: Int) -> Bool {
        verse >= startVerse && verse <= endVerse
    }

    public func overlaps(start: Int, end: Int) -> Bool {
        max(startVerse, min(start, end)) <= min(endVerse, max(start, end))
    }
}

@Model
public final class BibleBookmark {
    @Attribute(.unique) public var id: String
    public var book: String
    public var chapter: Int
    public var startVerse: Int
    public var endVerse: Int
    public var createdAt: Date
    public var verseText: String

    public init(
        id: String = UUID().uuidString,
        book: String,
        chapter: Int,
        startVerse: Int,
        endVerse: Int? = nil,
        createdAt: Date = .now,
        verseText: String = ""
    ) {
        self.id = id
        self.book = book
        self.chapter = chapter
        let end = endVerse ?? startVerse
        self.startVerse = min(startVerse, end)
        self.endVerse = max(startVerse, end)
        self.createdAt = createdAt
        self.verseText = verseText
    }

    public func contains(verse: Int) -> Bool {
        verse >= startVerse && verse <= endVerse
    }

    public func overlaps(start: Int, end: Int) -> Bool {
        max(startVerse, min(start, end)) <= min(endVerse, max(start, end))
    }
}

@Model
public final class BibleNote {
    @Attribute(.unique) public var id: String
    public var book: String
    public var chapter: Int
    public var startVerse: Int
    public var endVerse: Int
    public var noteText: String
    public var createdAt: Date
    public var updatedAt: Date
    public var verseText: String

    public init(
        id: String = UUID().uuidString,
        book: String,
        chapter: Int,
        startVerse: Int,
        endVerse: Int? = nil,
        noteText: String,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        verseText: String = ""
    ) {
        self.id = id
        self.book = book
        self.chapter = chapter
        let end = endVerse ?? startVerse
        self.startVerse = min(startVerse, end)
        self.endVerse = max(startVerse, end)
        self.noteText = noteText
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.verseText = verseText
    }

    public func contains(verse: Int) -> Bool {
        verse >= startVerse && verse <= endVerse
    }

    public func overlaps(start: Int, end: Int) -> Bool {
        max(startVerse, min(start, end)) <= min(endVerse, max(start, end))
    }
}
