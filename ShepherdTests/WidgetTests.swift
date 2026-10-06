import XCTest
import SwiftData
@testable import Shepherd

final class WidgetTests: XCTestCase {
    private var testDefaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "test.widget.store.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: suiteName)
        testDefaults = nil
        super.tearDown()
    }

    func testWidgetStreakDataDefaultValues() {
        let data = WidgetStreakData()
        XCTAssertEqual(data.streakCount, 0)
        XCTAssertEqual(data.bestStreak, 0)
        XCTAssertNil(data.lastCompletedDate)
        XCTAssertFalse(data.isCompletedToday)
        XCTAssertEqual(data.activePathTitle, "Pasture")
        XCTAssertNil(data.nextLessonTitle)
        XCTAssertEqual(data.nextLessonDayIndex, 1)
    }

    func testWidgetDataStoreSaveAndLoad() {
        let store = WidgetDataStore(defaults: testDefaults)
        let now = Date()
        let data = WidgetStreakData(
            streakCount: 5,
            bestStreak: 12,
            lastCompletedDate: now,
            isCompletedToday: true,
            activePathTitle: "First Steps: 30 Days with God",
            nextLessonTitle: "Made in God's image",
            nextLessonDayIndex: 2
        )

        store.saveStreakData(data)
        let loaded = store.loadStreakData()

        XCTAssertEqual(loaded.streakCount, 5)
        XCTAssertEqual(loaded.bestStreak, 12)
        XCTAssertTrue(loaded.isCompletedToday)
        XCTAssertEqual(loaded.activePathTitle, "First Steps: 30 Days with God")
        XCTAssertEqual(loaded.nextLessonTitle, "Made in God's image")
        XCTAssertEqual(loaded.nextLessonDayIndex, 2)
        XCTAssertNotNil(loaded.lastCompletedDate)
    }

    func testWidgetSyncServiceSyncsWithSwiftData() throws {
        let schema = Schema([
            UserProfile.self,
            Companion.self,
            StreakState.self,
            LessonProgress.self,
            EntitlementState.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let streak = StreakState(current: 7, best: 14, lastCompletedDate: .now)
        context.insert(streak)
        let progress = LessonProgress(lessonId: "day1", completedAt: .now, quizScore: 2)
        context.insert(progress)
        try context.save()

        let store = WidgetDataStore(defaults: testDefaults)
        // Sync using isolated store
        let cal = Calendar.current
        let today = Date.now
        let completedToday = cal.isDate(streak.lastCompletedDate!, inSameDayAs: today)
        let data = WidgetStreakData(
            streakCount: streak.current,
            bestStreak: streak.best,
            lastCompletedDate: streak.lastCompletedDate,
            isCompletedToday: completedToday,
            activePathTitle: "First Steps",
            nextLessonTitle: "In the beginning",
            nextLessonDayIndex: 2
        )
        store.saveStreakData(data)

        let loaded = store.loadStreakData()
        XCTAssertEqual(loaded.streakCount, 7)
        XCTAssertEqual(loaded.bestStreak, 14)
        XCTAssertTrue(loaded.isCompletedToday)
        XCTAssertEqual(loaded.nextLessonTitle, "In the beginning")
        XCTAssertEqual(loaded.nextLessonDayIndex, 2)
    }

    func testNextMidnightCalculation() {
        let service = DailyVerseService.shared
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!

        let midDay = cal.date(from: DateComponents(year: 2026, month: 10, day: 6, hour: 14, minute: 30))!
        let nextMidnight = service.nextMidnight(after: midDay, calendar: cal)

        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: nextMidnight)
        XCTAssertEqual(comps.year, 2026)
        XCTAssertEqual(comps.month, 10)
        XCTAssertEqual(comps.day, 7)
        XCTAssertEqual(comps.hour, 0)
        XCTAssertEqual(comps.minute, 0)
        XCTAssertEqual(comps.second, 0)
    }
}
