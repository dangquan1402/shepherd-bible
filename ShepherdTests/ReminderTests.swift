import XCTest
import SwiftData
import UserNotifications
@testable import Shepherd

/// The daily reminder: when it fires, that a finished lesson cancels today's, and that the
/// permission prompt and the copy behave.
@MainActor
final class ReminderTests: XCTestCase {

    /// Stands in for UNUserNotificationCenter: records requests instead of scheduling them.
    final class FakeCenter: ReminderNotificationCenter, @unchecked Sendable {
        var status: UNAuthorizationStatus = .notDetermined
        var grants = true
        var authorizationRequests = 0
        var pending: [UNNotificationRequest] = []
        var removedDelivered: [String] = []

        func add(_ request: UNNotificationRequest) async throws {
            pending.removeAll { $0.identifier == request.identifier }
            pending.append(request)
        }
        func pendingNotificationRequests() async -> [UNNotificationRequest] { pending }
        func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
            pending.removeAll { identifiers.contains($0.identifier) }
        }
        func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
            removedDelivered += identifiers
        }
        func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
            authorizationRequests += 1
            status = grants ? .authorized : .denied
            return grants
        }
        func reminderAuthorizationStatus() async -> UNAuthorizationStatus { status }
    }

    private var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/New_York")!
        return c
    }()

    private func date(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: mo, day: d, hour: h, minute: mi))!
    }

    private func freshDefaults() -> UserDefaults {
        let name = "ReminderTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    private func fireDates(_ center: FakeCenter) -> [Date] {
        center.pending
            .compactMap { ($0.trigger as? UNCalendarNotificationTrigger)?.dateComponents }
            .compactMap { calendar.date(from: $0) }
            .sorted()
    }

    // MARK: - Planner

    func testPlanFiresAtTheChosenTimeEveryDay() {
        let settings = ReminderSettings(isEnabled: true, hour: 19, minute: 30)
        let now = date(2026, 10, 6, 9, 0)
        let plan = ReminderPlanner.plan(settings: settings, now: now, completedToday: false, calendar: calendar)
        XCTAssertEqual(plan.count, ReminderPlanner.daysAhead)
        XCTAssertEqual(plan.first?.fireDate, date(2026, 10, 6, 19, 30), "today's reminder is at the chosen time")
        for (i, item) in plan.enumerated() {
            XCTAssertEqual(item.fireDate, calendar.date(byAdding: .day, value: i, to: date(2026, 10, 6, 19, 30)))
            XCTAssertEqual(item.dateComponents.hour, 19)
            XCTAssertEqual(item.dateComponents.minute, 30)
        }
        XCTAssertEqual(plan.first?.identifier, "daily-reminder-2026-10-06")
        XCTAssertEqual(Set(plan.map(\.identifier)).count, plan.count)
        // Varied copy: consecutive days never repeat a message.
        for (a, b) in zip(plan, plan.dropFirst()) {
            XCTAssertNotEqual(a.body, b.body)
        }
    }

    func testPlanKeepsLocalTimeAcrossDaylightSaving() {
        // US clocks go back on 2026-11-01: the reminder stays at 08:00 local time.
        let settings = ReminderSettings(isEnabled: true, hour: 8, minute: 0)
        let plan = ReminderPlanner.plan(settings: settings, now: date(2026, 10, 28, 6, 0), completedToday: false, calendar: calendar)
        for item in plan {
            XCTAssertEqual(calendar.component(.hour, from: item.fireDate), 8)
        }
    }

    func testPlanSkipsTodayWhenTheLessonIsDone() {
        let settings = ReminderSettings(isEnabled: true, hour: 19, minute: 30)
        let now = date(2026, 10, 6, 9, 0)
        let plan = ReminderPlanner.plan(settings: settings, now: now, completedToday: true, calendar: calendar)
        XCTAssertEqual(plan.first?.fireDate, date(2026, 10, 7, 19, 30), "today's reminder is skipped")
        XCTAssertFalse(plan.contains { $0.identifier == "daily-reminder-2026-10-06" })
        XCTAssertEqual(plan.count, ReminderPlanner.daysAhead - 1)
    }

    func testPlanSkipsTodayWhenTheTimeHasPassed() {
        let settings = ReminderSettings(isEnabled: true, hour: 7, minute: 0)
        let plan = ReminderPlanner.plan(settings: settings, now: date(2026, 10, 6, 9, 0), completedToday: false, calendar: calendar)
        XCTAssertEqual(plan.first?.fireDate, date(2026, 10, 7, 7, 0))
    }

    func testPlanIsEmptyWhenOff() {
        let plan = ReminderPlanner.plan(settings: ReminderSettings(isEnabled: false), now: date(2026, 10, 6, 6, 0), completedToday: false, calendar: calendar)
        XCTAssertTrue(plan.isEmpty)
        XCTAssertFalse(ReminderSettings().isEnabled, "the reminder is off by default")
    }

    func testReminderCopyIsGentle() {
        XCTAssertGreaterThanOrEqual(ReminderPlanner.messages.count, 5)
        for message in ReminderPlanner.messages {
            let text = (message.title + " " + message.body).lowercased()
            for word in ["streak", "miss", "lose", "lost", "don’t", "don't", "forget", "behind", "premium", "trial", "!"] {
                XCTAssertFalse(text.contains(word), "reminder copy uses '\(word)': \(text)")
            }
        }
    }

    // MARK: - Scheduling against the notification center

    func testEnableAsksOnceThenSchedulesAtTheTime() async {
        let center = FakeCenter()
        let reminder = DailyReminder(center: center, defaults: freshDefaults(), calendar: calendar)
        let now = date(2026, 10, 6, 9, 0)
        let result = await reminder.enable(hour: 20, minute: 15, completedToday: false, now: now)
        XCTAssertEqual(result, .scheduled)
        XCTAssertEqual(center.authorizationRequests, 1)
        XCTAssertTrue(reminder.settings.isEnabled)
        XCTAssertEqual(center.pending.count, ReminderPlanner.daysAhead)
        XCTAssertEqual(fireDates(center).first, date(2026, 10, 6, 20, 15))
        XCTAssertTrue(center.pending.allSatisfy { ($0.trigger as? UNCalendarNotificationTrigger)?.repeats == false })

        // Rescheduling replaces the window instead of adding to it.
        await reminder.reschedule(completedToday: false, now: now)
        XCTAssertEqual(center.pending.count, ReminderPlanner.daysAhead)
        XCTAssertEqual(center.authorizationRequests, 1, "permission is asked only once")
    }

    func testCompletingTodaysLessonCancelsTodaysReminder() async {
        let center = FakeCenter()
        center.status = .authorized
        let reminder = DailyReminder(center: center, defaults: freshDefaults(), calendar: calendar)
        let now = date(2026, 10, 6, 9, 0)
        await reminder.enable(hour: 19, minute: 0, completedToday: false, now: now)
        XCTAssertTrue(center.pending.contains { $0.identifier == "daily-reminder-2026-10-06" })

        let later = date(2026, 10, 6, 12, 0)
        await reminder.reschedule(completedToday: true, now: later)
        XCTAssertFalse(center.pending.contains { $0.identifier == "daily-reminder-2026-10-06" }, "today's reminder is still pending")
        XCTAssertEqual(fireDates(center).first, date(2026, 10, 7, 19, 0), "the next reminder is not tomorrow's")
        XCTAssertTrue(center.removedDelivered.contains("daily-reminder-2026-10-06"))
    }

    func testDisableCancelsEverything() async {
        let center = FakeCenter()
        center.status = .authorized
        let unrelated = UNNotificationRequest(identifier: "other", content: UNNotificationContent(), trigger: nil)
        center.pending = [unrelated]
        let defaults = freshDefaults()
        let reminder = DailyReminder(center: center, defaults: defaults, calendar: calendar)
        await reminder.enable(hour: 19, minute: 0, completedToday: false, now: date(2026, 10, 6, 9, 0))
        await reminder.disable()
        XCTAssertEqual(center.pending.map(\.identifier), ["other"])
        XCTAssertFalse(ReminderSettings.load(from: defaults).isEnabled)
    }

    func testDeniedPermissionLeavesTheReminderOff() async {
        let center = FakeCenter()
        center.grants = false
        let reminder = DailyReminder(center: center, defaults: freshDefaults(), calendar: calendar)
        let result = await reminder.enable(hour: 19, minute: 0, completedToday: false, now: date(2026, 10, 6, 9, 0))
        XCTAssertEqual(result, .denied)
        XCTAssertFalse(reminder.settings.isEnabled)
        XCTAssertTrue(center.pending.isEmpty)

        // Already denied in iOS Settings: no second prompt, still off.
        let again = await reminder.enable(completedToday: false, now: date(2026, 10, 6, 9, 0))
        XCTAssertEqual(again, .denied)
        XCTAssertEqual(center.authorizationRequests, 1)
    }

    func testSettingsPersist() {
        let defaults = freshDefaults()
        XCTAssertEqual(ReminderSettings.load(from: defaults), ReminderSettings(isEnabled: false, hour: 8, minute: 0))
        ReminderSettings(isEnabled: true, hour: 21, minute: 45).save(to: defaults)
        XCTAssertEqual(ReminderSettings.load(from: defaults), ReminderSettings(isEnabled: true, hour: 21, minute: 45))
    }

    func testCompletedTodayReadsLessonProgress() throws {
        let container = try ModelContainer(for: LessonProgress.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let now = Date.now
        context.insert(LessonProgress(lessonId: "day1", completedAt: Calendar.current.date(byAdding: .day, value: -1, to: now)!, quizScore: 2))
        try context.save()
        XCTAssertFalse(DailyReminder.hasCompletedLesson(on: now, in: context), "yesterday's lesson does not count for today")
        context.insert(LessonProgress(lessonId: "day2", completedAt: now, quizScore: 2))
        try context.save()
        XCTAssertTrue(DailyReminder.hasCompletedLesson(on: now, in: context))
    }
}
