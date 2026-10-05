import Foundation
import SwiftData

@Model
final class UserProfile {
    var displayName: String?
    var goal: String
    var experienceLevel: String
    var dailyMinutes: Int
    var createdAt: Date
    var hasCompletedOnboarding: Bool

    init(
        displayName: String? = nil,
        goal: String = "grow_daily",
        experienceLevel: String = "beginner",
        dailyMinutes: Int = 5,
        createdAt: Date = .now,
        hasCompletedOnboarding: Bool = true
    ) {
        self.displayName = displayName
        self.goal = goal
        self.experienceLevel = experienceLevel
        self.dailyMinutes = dailyMinutes
        self.createdAt = createdAt
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}

@Model
final class Companion {
    var name: String
    var stage: Int
    var xp: Int
    var outfitId: String?

    init(name: String = "Lamb", stage: Int = 1, xp: Int = 0, outfitId: String? = nil) {
        self.name = name
        self.stage = stage
        self.xp = xp
        self.outfitId = outfitId
    }

    func addXP(_ amount: Int) {
        xp += amount
        stage = max(1, min(5, 1 + xp / 50))
    }
}

@Model
final class StreakState {
    var current: Int
    var best: Int
    var lastCompletedDate: Date?
    var freezesLeft: Int

    init(current: Int = 0, best: Int = 0, lastCompletedDate: Date? = nil, freezesLeft: Int = 1) {
        self.current = current
        self.best = best
        self.lastCompletedDate = lastCompletedDate
        self.freezesLeft = freezesLeft
    }

    func markCompleted(on day: Date = .now) {
        let cal = Calendar.current
        if let last = lastCompletedDate, cal.isDate(last, inSameDayAs: day) {
            return
        }
        if let last = lastCompletedDate,
           let yesterday = cal.date(byAdding: .day, value: -1, to: day),
           cal.isDate(last, inSameDayAs: yesterday) {
            current += 1
        } else {
            current = 1
        }
        best = max(best, current)
        lastCompletedDate = day
    }
}

@Model
final class LessonProgress {
    @Attribute(.unique) var lessonId: String
    var completedAt: Date
    var quizScore: Int

    init(lessonId: String, completedAt: Date = .now, quizScore: Int) {
        self.lessonId = lessonId
        self.completedAt = completedAt
        self.quizScore = quizScore
    }
}

@Model
final class EntitlementState {
    var isPremium: Bool
    var expirationDate: Date?
    var productId: String?

    init(isPremium: Bool = false, expirationDate: Date? = nil, productId: String? = nil) {
        self.isPremium = isPremium
        self.expirationDate = expirationDate
        self.productId = productId
    }
}
