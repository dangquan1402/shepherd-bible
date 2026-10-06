import Foundation
import SwiftData

public enum WidgetSyncService {
    public static func sync(
        context: ModelContext,
        activePathTitle: String = "Pasture",
        nextLessonTitle: String? = nil,
        nextLessonDayIndex: Int? = 1
    ) {
        let streak = (try? context.fetch(FetchDescriptor<StreakState>()))?.first
        let progress = (try? context.fetch(FetchDescriptor<LessonProgress>())) ?? []

        let cal = Calendar.current
        let today = Date.now
        let completedToday: Bool = {
            if let last = streak?.lastCompletedDate, cal.isDate(last, inSameDayAs: today) {
                return true
            }
            return progress.contains { cal.isDate($0.completedAt, inSameDayAs: today) }
        }()

        let data = WidgetStreakData(
            streakCount: streak?.current ?? 0,
            bestStreak: streak?.best ?? 0,
            lastCompletedDate: streak?.lastCompletedDate,
            isCompletedToday: completedToday,
            activePathTitle: activePathTitle,
            nextLessonTitle: nextLessonTitle,
            nextLessonDayIndex: nextLessonDayIndex
        )
        WidgetDataStore.shared.saveStreakData(data)
    }
}
