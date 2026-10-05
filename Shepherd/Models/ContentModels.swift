import Foundation

public struct BibleBundle: Codable, Sendable {
    public let translation: String
    public let books: [BibleBook]

    public init(translation: String, books: [BibleBook]) {
        self.translation = translation
        self.books = books
    }
}

public struct BibleBook: Codable, Identifiable, Sendable {
    public var id: String { abbrev }
    public let name: String
    public let abbrev: String
    public let order: Int
    public let testament: String
    public let chapters: [BibleChapter]

    public init(name: String, abbrev: String, order: Int, testament: String, chapters: [BibleChapter]) {
        self.name = name
        self.abbrev = abbrev
        self.order = order
        self.testament = testament
        self.chapters = chapters
    }
}

public struct BibleChapter: Codable, Identifiable, Sendable {
    public var id: String { "\(number)" }
    public let number: Int
    public let verses: [BibleVerse]

    public init(number: Int, verses: [BibleVerse]) {
        self.number = number
        self.verses = verses
    }
}

public struct BibleVerse: Codable, Identifiable, Sendable {
    public var id: String { "\(number)" }
    public let number: Int
    public let text: String

    public init(number: Int, text: String) {
        self.number = number
        self.text = text
    }
}

public struct PathBundle: Codable, Sendable {
    public let paths: [StudyPath]

    public init(paths: [StudyPath]) {
        self.paths = paths
    }
}

public struct StudyPath: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let level: String
    public let estimatedDays: Int
    public let lessons: [Lesson]

    public init(id: String, title: String, level: String, estimatedDays: Int, lessons: [Lesson]) {
        self.id = id
        self.title = title
        self.level = level
        self.estimatedDays = estimatedDays
        self.lessons = lessons
    }
}

public struct Lesson: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let dayIndex: Int
    public let title: String
    public let verseRefs: [String]
    public let bodyMarkdown: String
    public let prayerPrompt: String?
    public let quiz: [QuizQuestion]

    public init(
        id: String,
        dayIndex: Int,
        title: String,
        verseRefs: [String],
        bodyMarkdown: String,
        prayerPrompt: String?,
        quiz: [QuizQuestion]
    ) {
        self.id = id
        self.dayIndex = dayIndex
        self.title = title
        self.verseRefs = verseRefs
        self.bodyMarkdown = bodyMarkdown
        self.prayerPrompt = prayerPrompt
        self.quiz = quiz
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Lesson, rhs: Lesson) -> Bool {
        lhs.id == rhs.id
    }
}

public struct QuizQuestion: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let prompt: String
    public let choices: [String]
    public let correctIndex: Int
    public let explain: String?

    public init(id: String, prompt: String, choices: [String], correctIndex: Int, explain: String?) {
        self.id = id
        self.prompt = prompt
        self.choices = choices
        self.correctIndex = correctIndex
        self.explain = explain
    }
}
