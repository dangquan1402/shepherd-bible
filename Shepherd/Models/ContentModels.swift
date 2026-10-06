import Foundation

public struct BibleBundle: Codable, Sendable {
    public let translation: String
    /// eBible.org edition id of the source text (`engwebp`); see tools/bible/build_web.py.
    public let edition: String?
    public let books: [BibleBook]

    public init(translation: String, edition: String? = nil, books: [BibleBook]) {
        self.translation = translation
        self.edition = edition
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
    /// A psalm's superscription ("A Psalm by David."), kept out of verse 1.
    public let heading: String?
    public let verses: [BibleVerse]

    public init(number: Int, heading: String? = nil, verses: [BibleVerse]) {
        self.number = number
        self.heading = heading
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
    public let contentVersion: Int?
    public let paths: [StudyPath]

    public init(contentVersion: Int? = nil, paths: [StudyPath]) {
        self.contentVersion = contentVersion
        self.paths = paths
    }
}

/// Who can open a path's lessons. Seasonal paths are free (report §5.1).
public enum PathAccess: String, Codable, Sendable {
    case free
    case premium
    case seasonal
}

/// Content metadata for a path that is still being written. Drafts are listed in the app so the
/// multi-path UI can be exercised, and `tools/content/validate_content.py --release` rejects them.
public struct PathDraft: Codable, Hashable, Sendable {
    public let plannedLessons: Int
    public let note: String?

    public init(plannedLessons: Int, note: String? = nil) {
        self.plannedLessons = plannedLessons
        self.note = note
    }
}

public struct StudyPath: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let level: String
    public let estimatedDays: Int
    public let sortOrder: Int
    public let access: PathAccess
    /// For `.premium` paths: how many lessons, from day 1, are free.
    public let freePreviewLessons: Int
    /// Onboarding goals and familiarity levels this path suits.
    public let goals: [String]
    public let levels: [String]
    public let draft: PathDraft?
    public let lessons: [Lesson]

    public var isDraft: Bool { draft != nil }

    public init(
        id: String,
        title: String,
        subtitle: String? = nil,
        level: String,
        estimatedDays: Int,
        sortOrder: Int = 0,
        access: PathAccess = .free,
        freePreviewLessons: Int = 0,
        goals: [String] = [],
        levels: [String] = [],
        draft: PathDraft? = nil,
        lessons: [Lesson]
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.level = level
        self.estimatedDays = estimatedDays
        self.sortOrder = sortOrder
        self.access = access
        self.freePreviewLessons = freePreviewLessons
        self.goals = goals
        self.levels = levels
        self.draft = draft
        self.lessons = lessons
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, subtitle, level, estimatedDays, sortOrder, access, freePreviewLessons, goals, levels, draft, lessons
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        subtitle = try c.decodeIfPresent(String.self, forKey: .subtitle)
        level = try c.decode(String.self, forKey: .level)
        estimatedDays = try c.decode(Int.self, forKey: .estimatedDays)
        sortOrder = try c.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        access = try c.decodeIfPresent(PathAccess.self, forKey: .access) ?? .free
        freePreviewLessons = try c.decodeIfPresent(Int.self, forKey: .freePreviewLessons) ?? 0
        goals = try c.decodeIfPresent([String].self, forKey: .goals) ?? []
        levels = try c.decodeIfPresent([String].self, forKey: .levels) ?? []
        draft = try c.decodeIfPresent(PathDraft.self, forKey: .draft)
        lessons = try c.decode([Lesson].self, forKey: .lessons)
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
    /// The lesson verse that proves the answer; shown after the question is checked.
    public let answerRef: String?
    public let explain: String?

    public init(id: String, prompt: String, choices: [String], correctIndex: Int, answerRef: String? = nil, explain: String?) {
        self.id = id
        self.prompt = prompt
        self.choices = choices
        self.correctIndex = correctIndex
        self.answerRef = answerRef
        self.explain = explain
    }
}
