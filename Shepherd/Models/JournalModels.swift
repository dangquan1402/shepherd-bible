import Foundation
import SwiftData

@Model
public final class JournalEntry {
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date
    public var lessonId: String?
    public var lessonTitle: String?
    public var prompt: String?
    public var text: String
    public var updatedAt: Date?

    public init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        lessonId: String? = nil,
        lessonTitle: String? = nil,
        prompt: String? = nil,
        text: String = "",
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.lessonId = lessonId
        self.lessonTitle = lessonTitle
        self.prompt = prompt
        self.text = text
        self.updatedAt = updatedAt
    }
}

@Model
public final class PrayerRequest {
    @Attribute(.unique) public var id: UUID
    public var text: String
    public var createdAt: Date
    public var isAnswered: Bool
    public var answeredDate: Date?
    public var notes: String?

    public init(
        id: UUID = UUID(),
        text: String = "",
        createdAt: Date = .now,
        isAnswered: Bool = false,
        answeredDate: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.isAnswered = isAnswered
        self.answeredDate = answeredDate
        self.notes = notes
    }

    public func markAnswered(on date: Date = .now) {
        isAnswered = true
        answeredDate = date
    }

    public func markUnanswered() {
        isAnswered = false
        answeredDate = nil
    }
}

extension JournalEntry {
    /// The journal entry for a reflection written after `lesson`, or nil when the text is blank
    /// (saving an empty reflection saves nothing).
    public static func reflection(on lesson: Lesson, text: String) -> JournalEntry? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return JournalEntry(
            lessonId: lesson.id,
            lessonTitle: lesson.title,
            prompt: lesson.prayerPrompt,
            text: trimmed
        )
    }
}

public enum PrayerFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case open = "Open"
    case answered = "Answered"

    public var id: String { rawValue }

    /// The prayers this filter shows, in their given order.
    public func apply(to prayers: [PrayerRequest]) -> [PrayerRequest] {
        switch self {
        case .all:
            return prayers
        case .open:
            return prayers.filter { !$0.isAnswered }
        case .answered:
            return prayers.filter { $0.isAnswered }
        }
    }
}

/// How the Reflections list is arranged.
public enum JournalGrouping: String, CaseIterable, Identifiable {
    case date = "By date"
    case path = "By path"

    public var id: String { rawValue }

    public struct Section: Identifiable {
        public let id: String
        public let title: String
        public let entries: [JournalEntry]
    }

    /// Entries grouped by the path their lesson belongs to, in catalog order. Entries not tied to
    /// a lesson in the catalog (written from the Journal itself) come last under "Your own
    /// reflections". Each section keeps the entries' given order.
    public static func byPath(_ entries: [JournalEntry], paths: [StudyPath]) -> [Section] {
        var pathIndexForLesson: [String: Int] = [:]
        for (index, path) in paths.enumerated() {
            for lesson in path.lessons {
                pathIndexForLesson[lesson.id] = index
            }
        }
        var byPath: [Int: [JournalEntry]] = [:]
        var unlinked: [JournalEntry] = []
        for entry in entries {
            if let lessonId = entry.lessonId, let index = pathIndexForLesson[lessonId] {
                byPath[index, default: []].append(entry)
            } else {
                unlinked.append(entry)
            }
        }
        var sections = byPath.keys.sorted().map { index in
            Section(id: paths[index].id, title: paths[index].title, entries: byPath[index] ?? [])
        }
        if !unlinked.isEmpty {
            sections.append(Section(id: "own", title: "Your own reflections", entries: unlinked))
        }
        return sections
    }
}
