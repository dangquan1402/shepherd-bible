import Foundation

public struct DailyVerseItem: Codable, Equatable, Sendable {
    public let day: Int?
    public let ref: String
    public let text: String

    public init(day: Int? = nil, ref: String, text: String) {
        self.day = day
        self.ref = ref
        self.text = text
    }
}

public struct DailyVerse: Identifiable, Equatable, Hashable, Sendable {
    public var id: String { ref }
    public let dayIndex: Int
    public let ref: String
    public let bookAbbrev: String
    public let chapter: Int
    public let verse: Int
    public let bookName: String
    public let displayRef: String
    public let text: String

    public init(
        dayIndex: Int,
        ref: String,
        bookAbbrev: String,
        chapter: Int,
        verse: Int,
        bookName: String,
        displayRef: String,
        text: String
    ) {
        self.dayIndex = dayIndex
        self.ref = ref
        self.bookAbbrev = bookAbbrev
        self.chapter = chapter
        self.verse = verse
        self.bookName = bookName
        self.displayRef = displayRef
        self.text = text
    }

    /// "Psalm 23:1. The LORD is my shepherd; I shall lack nothing. World English Bible." without
    /// doubling the verse's own closing punctuation.
    public var spokenLabel: String {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        let closed = trimmed.last.map { ".!?\u{201D}\u{2019}\"'".contains($0) } ?? false
        return "\(displayRef). \(trimmed)\(closed ? "" : ".") World English Bible."
    }
}
