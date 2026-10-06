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

    /// Representative swatch dot tint for UI buttons
    public var swatchColor: Color {
        switch self {
        case .yellow: return ShepherdTheme.gold
        case .blue: return ShepherdTheme.accent
        case .purple: return Color("Note")
        case .rose: return Color("MascotBlush")
        case .amber: return Color("GoldFill")
        }
    }
}

// MARK: - Formatted Scripture Helper

public enum BibleFormatter {
    /// Formats scripture for copying and sharing: text + reference + "World English Bible" attribution.
    public static func formattedText(
        bookName: String,
        chapter: Int,
        startVerse: Int,
        endVerse: Int,
        verseTexts: [String]
    ) -> String {
        let combinedText = verseTexts.joined(separator: " ")
        let reference = referenceString(bookName: bookName, chapter: chapter, startVerse: startVerse, endVerse: endVerse)
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
        if startVerse == endVerse {
            return "\(bookName) \(chapter):\(startVerse)"
        } else {
            return "\(bookName) \(chapter):\(startVerse)–\(endVerse)"
        }
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
