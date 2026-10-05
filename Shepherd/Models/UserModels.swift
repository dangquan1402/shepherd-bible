import Foundation
import SwiftData

@Model
public final class UserProfile {
    public var displayName: String?
    public var goal: String
    public var experienceLevel: String
    public var dailyMinutes: Int
    public var createdAt: Date
    public var hasCompletedOnboarding: Bool

    public init(
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
public final class Companion {
    public var name: String
    public var stage: Int
    public var xp: Int
    public var outfitId: String?

    public init(name: String = "Lamb", stage: Int = 1, xp: Int = 0, outfitId: String? = nil) {
        self.name = name
        self.stage = stage
        self.xp = xp
        self.outfitId = outfitId
    }

    public func addXP(_ amount: Int) {
        xp += amount
        stage = max(1, min(5, 1 + xp / 50))
    }
}

@Model
public final class StreakState {
    public var current: Int
    public var best: Int
    public var lastCompletedDate: Date?
    public var freezesLeft: Int

    public init(current: Int = 0, best: Int = 0, lastCompletedDate: Date? = nil, freezesLeft: Int = 1) {
        self.current = current
        self.best = best
        self.lastCompletedDate = lastCompletedDate
        self.freezesLeft = freezesLeft
    }

    public func markCompleted(on day: Date = .now) {
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

    public func consumeFreeze(isPremium: Bool) -> Bool {
        guard Entitlements.isUnlocked(.streakFreezes, isPremium: isPremium) else {
            return false
        }
        if freezesLeft > 0 {
            freezesLeft -= 1
            return true
        }
        return false
    }
}

@Model
public final class LessonProgress {
    @Attribute(.unique) public var lessonId: String
    public var completedAt: Date
    public var quizScore: Int

    public var isCompleted: Bool { true }

    public init(lessonId: String, completedAt: Date = .now, quizScore: Int) {
        self.lessonId = lessonId
        self.completedAt = completedAt
        self.quizScore = quizScore
    }
}

@Model
public final class EntitlementState {
    public var isPremium: Bool
    public var expirationDate: Date?
    public var productId: String?

    public init(isPremium: Bool = false, expirationDate: Date? = nil, productId: String? = nil) {
        self.isPremium = isPremium
        self.expirationDate = expirationDate
        self.productId = productId
    }
}
