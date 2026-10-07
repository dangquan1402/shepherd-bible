import Foundation
import SwiftData

/// Publishes streak and progress for the widgets. Every writer (launch, scene activation, lesson
/// completion, path switch) goes through `sync`, so they all agree on what "next" means.
public enum WidgetSyncService {
    /// The widget snapshot for the current store: streak, last completion, and the active
    /// path's next lesson (the first one not yet completed; nil when the path is finished).
    public static func snapshot(context: ModelContext, activePath: StudyPath?) -> WidgetStreakData {
        let streak = (try? context.fetch(FetchDescriptor<StreakState>()))?.first
        let completed = Set(((try? context.fetch(FetchDescriptor<LessonProgress>())) ?? []).map(\.lessonId))
        let next = activePath.flatMap { PathProgress.nextLesson(in: $0, completed: completed) }
        return WidgetStreakData(
            streakCount: streak?.current ?? 0,
            bestStreak: streak?.best ?? 0,
            lastCompletedDate: streak?.lastCompletedDate,
            activePathTitle: activePath?.title ?? "Pasture",
            nextLessonTitle: next?.title,
            nextLessonDayIndex: next?.dayIndex
        )
    }

    public static func sync(context: ModelContext, activePath: StudyPath?, store: WidgetDataStore = .shared) {
        store.saveStreakData(snapshot(context: context, activePath: activePath))
    }
}
