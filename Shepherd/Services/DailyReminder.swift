import Foundation
import SwiftData
import UserNotifications

/// The opt-in daily reminder. Local notifications only: nothing is sent anywhere, and the
/// permission prompt appears only when the user turns the reminder on.
///
/// A single repeating trigger cannot skip a day or change its words, so the reminder is a rolling
/// window of one-shot notifications (`ReminderPlanner.daysAhead` days), refilled whenever the app
/// becomes active or a lesson is completed. Today's is left out once a lesson is done today.
/// If Pasture is not opened for that long, the reminders stop until it is opened again.
public struct ReminderSettings: Equatable, Sendable {
    public var isEnabled: Bool
    public var hour: Int
    public var minute: Int

    public init(isEnabled: Bool = false, hour: Int = 8, minute: Int = 0) {
        self.isEnabled = isEnabled
        self.hour = hour
        self.minute = minute
    }

    static let enabledKey = "reminder.enabled"
    static let hourKey = "reminder.hour"
    static let minuteKey = "reminder.minute"

    public static func load(from defaults: UserDefaults) -> ReminderSettings {
        var settings = ReminderSettings()
        settings.isEnabled = defaults.bool(forKey: enabledKey)
        if defaults.object(forKey: hourKey) != nil {
            settings.hour = defaults.integer(forKey: hourKey)
            settings.minute = defaults.integer(forKey: minuteKey)
        }
        return settings
    }

    public func save(to defaults: UserDefaults) {
        defaults.set(isEnabled, forKey: Self.enabledKey)
        defaults.set(hour, forKey: Self.hourKey)
        defaults.set(minute, forKey: Self.minuteKey)
    }
}

public enum ReminderPlanner {
    public static let identifierPrefix = "daily-reminder-"
    public static let daysAhead = 14

    /// Calm, varied copy. Never streak, loss or guilt language (`testReminderCopyIsGentle`).
    public static let messages: [(title: String, body: String)] = [
        ("Your lamb is ready", "Today’s lesson is waiting whenever you are."),
        ("A few quiet minutes", "Today’s verse is ready for you."),
        ("Today’s lesson", "One short reading and a question or two. Come as you are."),
        ("A verse for today", "Take a breath and read today’s passage with your lamb."),
        ("The pasture is quiet", "A good moment for today’s lesson, if you have one."),
        ("Ready when you are", "Your lamb saved you a spot for today’s lesson."),
        ("Your daily path", "Today’s step on your path is ready."),
    ]

    public struct Planned: Equatable, Sendable {
        public let identifier: String
        public let fireDate: Date
        public let dateComponents: DateComponents
        public let title: String
        public let body: String
    }

    public static func identifier(for day: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: day)
        return identifierPrefix + String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// The reminders to have pending at `now`: one per day at the chosen time, starting today,
    /// skipping today when its time has passed or a lesson is already done today.
    public static func plan(
        settings: ReminderSettings,
        now: Date,
        completedToday: Bool,
        calendar: Calendar = .current
    ) -> [Planned] {
        guard settings.isEnabled else { return [] }
        let today = calendar.startOfDay(for: now)
        var planned: [Planned] = []
        for offset in 0..<daysAhead {
            if offset == 0 && completedToday { continue }
            guard let day = calendar.date(byAdding: .day, value: offset, to: today),
                  let fire = calendar.date(bySettingHour: settings.hour, minute: settings.minute, second: 0, of: day),
                  fire > now else { continue }
            // Same message for the same date on every reschedule; the next day gets the next one.
            let dayNumber = calendar.ordinality(of: .day, in: .era, for: day) ?? offset
            let message = messages[dayNumber % messages.count]
            planned.append(Planned(
                identifier: identifier(for: day, calendar: calendar),
                fireDate: fire,
                dateComponents: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire),
                title: message.title,
                body: message.body
            ))
        }
        return planned
    }
}

/// The parts of `UNUserNotificationCenter` the reminder uses, so tests can use a fake.
public protocol ReminderNotificationCenter: AnyObject, Sendable {
    func add(_ request: UNNotificationRequest) async throws
    func pendingNotificationRequests() async -> [UNNotificationRequest]
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    func removeDeliveredNotifications(withIdentifiers identifiers: [String])
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func reminderAuthorizationStatus() async -> UNAuthorizationStatus
}

extension UNUserNotificationCenter: ReminderNotificationCenter {
    public func reminderAuthorizationStatus() async -> UNAuthorizationStatus {
        await notificationSettings().authorizationStatus
    }
}

@MainActor
public final class DailyReminder: ObservableObject {
    public static let shared = DailyReminder(center: UNUserNotificationCenter.current(), defaults: .standard)

    public enum EnableResult: Equatable {
        case scheduled
        /// Notifications are off for Pasture in iOS Settings; the reminder stays off.
        case denied
    }

    @Published public private(set) var settings: ReminderSettings
    private let center: ReminderNotificationCenter
    private let defaults: UserDefaults
    private let calendar: Calendar
    private var lastCompletedToday = false

    public init(center: ReminderNotificationCenter, defaults: UserDefaults, calendar: Calendar = .current) {
        self.center = center
        self.defaults = defaults
        self.calendar = calendar
        self.settings = ReminderSettings.load(from: defaults)
    }

    /// Asks for permission if it has never been asked, then turns the reminder on.
    @discardableResult
    public func enable(hour: Int? = nil, minute: Int? = nil, completedToday: Bool = false, now: Date = .now) async -> EnableResult {
        var granted: Bool
        switch await center.reminderAuthorizationStatus() {
        case .notDetermined:
            granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        case .denied:
            granted = false
        default:
            granted = true
        }
        guard granted else {
            settings.isEnabled = false
            settings.save(to: defaults)
            await reschedule(completedToday: completedToday, now: now)
            return .denied
        }
        settings.isEnabled = true
        if let hour { settings.hour = hour }
        if let minute { settings.minute = minute }
        settings.save(to: defaults)
        await reschedule(completedToday: completedToday, now: now)
        return .scheduled
    }

    public func disable() async {
        settings.isEnabled = false
        settings.save(to: defaults)
        await reschedule(completedToday: lastCompletedToday)
    }

    public func setTime(hour: Int, minute: Int, completedToday: Bool, now: Date = .now) async {
        settings.hour = hour
        settings.minute = minute
        settings.save(to: defaults)
        await reschedule(completedToday: completedToday, now: now)
    }

    public func authorizationStatus() async -> UNAuthorizationStatus {
        await center.reminderAuthorizationStatus()
    }

    /// Replaces every pending reminder with the current plan. When a lesson is done today,
    /// today's reminder is cancelled, and cleared from Notification Center if it was delivered.
    public func reschedule(completedToday: Bool, now: Date = .now) async {
        lastCompletedToday = completedToday
        let pending = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(ReminderPlanner.identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: pending)
        if completedToday {
            center.removeDeliveredNotifications(withIdentifiers: [ReminderPlanner.identifier(for: now, calendar: calendar)])
        }
        for item in ReminderPlanner.plan(settings: settings, now: now, completedToday: completedToday, calendar: calendar) {
            let content = UNMutableNotificationContent()
            content.title = item.title
            content.body = item.body
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: item.dateComponents, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: item.identifier, content: content, trigger: trigger))
        }
    }

    /// Reschedules from the stored progress: today counts as done when any lesson was completed today.
    public func refresh(context: ModelContext, now: Date = .now) async {
        await reschedule(completedToday: Self.hasCompletedLesson(on: now, in: context, calendar: calendar), now: now)
    }

    public static func hasCompletedLesson(on day: Date, in context: ModelContext, calendar: Calendar = .current) -> Bool {
        let start = calendar.startOfDay(for: day)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return false }
        var descriptor = FetchDescriptor<LessonProgress>(predicate: #Predicate { $0.completedAt >= start && $0.completedAt < end })
        descriptor.fetchLimit = 1
        return ((try? context.fetchCount(descriptor)) ?? 0) > 0
    }
}
