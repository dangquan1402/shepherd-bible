import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

public struct WidgetStreakData: Codable, Equatable, Sendable {
    public let streakCount: Int
    public let bestStreak: Int
    public let lastCompletedDate: Date?
    public let isCompletedToday: Bool
    public let activePathTitle: String
    public let nextLessonTitle: String?
    public let nextLessonDayIndex: Int?

    public init(
        streakCount: Int = 0,
        bestStreak: Int = 0,
        lastCompletedDate: Date? = nil,
        isCompletedToday: Bool = false,
        activePathTitle: String = "Pasture",
        nextLessonTitle: String? = nil,
        nextLessonDayIndex: Int? = 1
    ) {
        self.streakCount = streakCount
        self.bestStreak = bestStreak
        self.lastCompletedDate = lastCompletedDate
        self.isCompletedToday = isCompletedToday
        self.activePathTitle = activePathTitle
        self.nextLessonTitle = nextLessonTitle
        self.nextLessonDayIndex = nextLessonDayIndex
    }
}

public final class WidgetDataStore: @unchecked Sendable {
    public static let shared = WidgetDataStore()
    public static let appGroupId = "group.com.dangvietquan.shepherd"
    public static let streakDataKey = "shepherd.widget.streak_data"

    public let defaults: UserDefaults?

    public init(defaults: UserDefaults? = UserDefaults(suiteName: appGroupId)) {
        self.defaults = defaults
    }

    public func saveStreakData(_ data: WidgetStreakData) {
        let def = defaults ?? UserDefaults.standard
        if let encoded = try? JSONEncoder().encode(data) {
            def.set(encoded, forKey: Self.streakDataKey)
        }
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    public func loadStreakData() -> WidgetStreakData {
        let def = defaults ?? UserDefaults.standard
        guard let data = def.data(forKey: Self.streakDataKey),
              let decoded = try? JSONDecoder().decode(WidgetStreakData.self, from: data) else {
            return WidgetStreakData()
        }
        return decoded
    }
}
