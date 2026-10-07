import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

// Compiled into both the app and the ShepherdWidgets extension (see project.yml).

/// URLs the widgets open in the app (`widgetURL`), also registered in CFBundleURLTypes.
public enum DeepLink {
    public static let scheme = "pasture"
    public static let verseHost = "verse"
    public static let lessonHost = "lesson"
    public static let verse = URL(string: "\(scheme)://\(verseHost)")!
    public static let lesson = URL(string: "\(scheme)://\(lessonHost)")!
}

/// What the app publishes for the streak widgets after launch and after each lesson.
/// Date-dependent state ("done today") is not stored: the widget derives it from
/// `lastCompletedDate` for each timeline entry, so it turns over at local midnight on its own.
public struct WidgetStreakData: Codable, Equatable, Sendable {
    public let streakCount: Int
    public let bestStreak: Int
    public let lastCompletedDate: Date?
    public let activePathTitle: String
    public let nextLessonTitle: String?
    /// nil once the active path is finished.
    public let nextLessonDayIndex: Int?

    public init(
        streakCount: Int = 0,
        bestStreak: Int = 0,
        lastCompletedDate: Date? = nil,
        activePathTitle: String = "Pasture",
        nextLessonTitle: String? = nil,
        nextLessonDayIndex: Int? = 1
    ) {
        self.streakCount = streakCount
        self.bestStreak = bestStreak
        self.lastCompletedDate = lastCompletedDate
        self.activePathTitle = activePathTitle
        self.nextLessonTitle = nextLessonTitle
        self.nextLessonDayIndex = nextLessonDayIndex
    }

    /// True when a lesson was completed on the same local day as `date`.
    public func isCompleted(on date: Date, calendar: Calendar = .current) -> Bool {
        guard let lastCompletedDate else { return false }
        return calendar.isDate(lastCompletedDate, inSameDayAs: date)
    }
}

public enum WidgetTimeline {
    /// Entry dates for a day-based widget: now, and the next local midnight (where "today"
    /// turns over). The timeline is reloaded after the last entry.
    public static func entryDates(from now: Date, calendar: Calendar = .current) -> [Date] {
        [now, nextMidnight(after: now, calendar: calendar)]
    }

    public static func nextMidnight(after date: Date, calendar: Calendar = .current) -> Date {
        calendar.nextDate(after: date, matching: DateComponents(hour: 0, minute: 0, second: 0), matchingPolicy: .nextTime)
            ?? calendar.startOfDay(for: date).addingTimeInterval(86400)
    }
}

public final class WidgetDataStore: @unchecked Sendable {
    public static let appGroupId = "group.com.dangvietquan.shepherd"
    public static let streakDataKey = "shepherd.widget.streak_data"

    /// The App Group container both processes share. Without the
    /// `com.apple.security.application-groups` entitlement this is nil and the app and the
    /// widget each get a private store, so the widget never sees the app's data.
    public static var isAppGroupAvailable: Bool {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) != nil
    }

    public static let shared: WidgetDataStore = {
        #if DEBUG
        if !isAppGroupAvailable {
            assertionFailure("App Group \(appGroupId) is missing from this target's entitlements; widgets cannot read app data")
        }
        #endif
        guard let defaults = UserDefaults(suiteName: appGroupId) else {
            preconditionFailure("UserDefaults(suiteName: \(appGroupId)) returned nil")
        }
        return WidgetDataStore(defaults: defaults)
    }()

    public let defaults: UserDefaults
    private let reloadsWidgets: Bool

    /// `reloadsWidgets: false` for tests that use a private suite.
    public init(defaults: UserDefaults, reloadsWidgets: Bool = true) {
        self.defaults = defaults
        self.reloadsWidgets = reloadsWidgets
    }

    public func saveStreakData(_ data: WidgetStreakData) {
        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: Self.streakDataKey)
        }
        #if canImport(WidgetKit)
        if reloadsWidgets {
            WidgetCenter.shared.reloadAllTimelines()
        }
        #endif
    }

    public func loadStreakData() -> WidgetStreakData {
        guard let data = defaults.data(forKey: Self.streakDataKey),
              let decoded = try? JSONDecoder().decode(WidgetStreakData.self, from: data) else {
            return WidgetStreakData()
        }
        return decoded
    }
}
