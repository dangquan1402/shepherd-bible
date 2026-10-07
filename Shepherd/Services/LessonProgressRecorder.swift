import Foundation
import SwiftData

public enum LessonProgressRecorder {
    public struct CompletionResult {
        public let wasAlreadyCompleted: Bool
        public let xpAwarded: Int
        public let oldXP: Int
        public let newXP: Int
        public let streakCount: Int

        public init(
            wasAlreadyCompleted: Bool,
            xpAwarded: Int,
            oldXP: Int,
            newXP: Int,
            streakCount: Int
        ) {
            self.wasAlreadyCompleted = wasAlreadyCompleted
            self.xpAwarded = xpAwarded
            self.oldXP = oldXP
            self.newXP = newXP
            self.streakCount = streakCount
        }
    }

    /// Records a finished lesson (XP, streak, progress row) and republishes the widget data.
    /// `activePath` is the path the Today tab follows; the widget's "next lesson" comes from it.
    @discardableResult
    public static func complete(
        lesson: Lesson,
        score: Int,
        context: ModelContext,
        isPremium: Bool = false,
        activePath: StudyPath? = nil,
        widgetStore: WidgetDataStore = .shared
    ) -> CompletionResult {
        let lessonId = lesson.id

        // Check if already completed
        let descriptor = FetchDescriptor<LessonProgress>(predicate: #Predicate { $0.lessonId == lessonId })
        let existingProgress = (try? context.fetch(descriptor))?.first
        let wasAlreadyCompleted = (existingProgress != nil)

        let companion = (try? context.fetch(FetchDescriptor<Companion>()))?.first
        let streak = (try? context.fetch(FetchDescriptor<StreakState>()))?.first

        let oldXP = companion?.xp ?? 0
        var xpAwarded = 0

        if !wasAlreadyCompleted {
            xpAwarded = Progression.xpEarned(score: score)
            companion?.addXP(xpAwarded)
            streak?.markCompleted(isPremium: isPremium)

            let newProgress = LessonProgress(lessonId: lessonId, quizScore: score)
            context.insert(newProgress)
        }

        try? context.save()

        WidgetSyncService.sync(context: context, activePath: activePath, store: widgetStore)

        let newXP = companion?.xp ?? 0
        let currentStreak = streak?.current ?? 1

        return CompletionResult(
            wasAlreadyCompleted: wasAlreadyCompleted,
            xpAwarded: xpAwarded,
            oldXP: oldXP,
            newXP: newXP,
            streakCount: currentStreak
        )
    }
}
