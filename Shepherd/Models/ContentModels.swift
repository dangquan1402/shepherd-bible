import Foundation

struct BibleBundle: Codable {
    let translation: String
    let books: [BibleBook]
}

struct BibleBook: Codable, Identifiable {
    var id: String { abbrev }
    let name: String
    let abbrev: String
    let order: Int
    let testament: String
    let chapters: [BibleChapter]
}

struct BibleChapter: Codable, Identifiable {
    var id: String { "\(number)" }
    let number: Int
    let verses: [BibleVerse]
}

struct BibleVerse: Codable, Identifiable {
    var id: String { "\(number)" }
    let number: Int
    let text: String
}

struct PathBundle: Codable {
    let paths: [StudyPath]
}

struct StudyPath: Codable, Identifiable {
    let id: String
    let title: String
    let level: String
    let estimatedDays: Int
    let lessons: [Lesson]
}

struct Lesson: Codable, Identifiable {
    let id: String
    let dayIndex: Int
    let title: String
    let verseRefs: [String]
    let bodyMarkdown: String
    let prayerPrompt: String?
    let quiz: [QuizQuestion]
}

struct QuizQuestion: Codable, Identifiable {
    let id: String
    let prompt: String
    let choices: [String]
    let correctIndex: Int
    let explain: String?
}
