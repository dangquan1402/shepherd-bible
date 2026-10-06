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
