import XCTest
import SwiftData
@testable import Shepherd

final class WidgetTests: XCTestCase {
    private var testDefaults: UserDefaults!
    private var suiteName: String!
    private var store: WidgetDataStore!

    override func setUp() {
        super.setUp()
        suiteName = "test.widget.store.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: suiteName)!
        store = WidgetDataStore(defaults: testDefaults, reloadsWidgets: false)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: suiteName)
        testDefaults = nil
        store = nil
        super.tearDown()
    }

    private var utc: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    private func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        utc.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    // MARK: - App Group (the widget and the app must share one store)

    /// The test host is the app; without the application-groups entitlement there is no shared
    /// container and the widget extension would read an empty private store.
    func testAppHasTheSharedAppGroupContainer() {
        XCTAssertTrue(WidgetDataStore.isAppGroupAvailable, "\(WidgetDataStore.appGroupId) is not in the app's entitlements")
    }

    func testWidgetDataStoreSaveAndLoad() {
        let now = Date()
        let data = WidgetStreakData(
            streakCount: 5,
            bestStreak: 12,
            lastCompletedDate: now,
            activePathTitle: "First Steps: 30 Days with God",
            nextLessonTitle: "Made in God's image",
            nextLessonDayIndex: 2
        )
        store.saveStreakData(data)
        XCTAssertEqual(store.loadStreakData(), data)
    }

    func testEmptyStoreLoadsDefaults() {
        XCTAssertEqual(store.loadStreakData(), WidgetStreakData())
    }

    // MARK: - Lesson completion publishes the real next lesson

    @MainActor
    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: UserProfile.self, Companion.self, StreakState.self, LessonProgress.self, EntitlementState.self,
            configurations: config
        )
        let context = ModelContext(container)
        context.insert(Companion())
        context.insert(StreakState())
        try context.save()
        return context
    }

    @MainActor
    private func beginnerPath() throws -> StudyPath {
        ContentStore.shared.loadIfNeeded()
        return try XCTUnwrap(ContentStore.shared.path(id: "beginner-30"))
    }

    @MainActor
    func testCompletingDay1PublishesDay2AsNext() throws {
        let context = try makeContext()
        let path = try beginnerPath()

        LessonProgressRecorder.complete(lesson: path.lessons[0], score: 2, context: context, activePath: path, widgetStore: store)

        let published = store.loadStreakData()
        XCTAssertEqual(published.nextLessonDayIndex, 2, "the widget's next lesson after finishing Day 1")
        XCTAssertEqual(published.nextLessonTitle, path.lessons[1].title)
        XCTAssertEqual(published.activePathTitle, path.title)
        XCTAssertEqual(published.streakCount, 1)
        XCTAssertTrue(published.isCompleted(on: .now), "the lesson just finished counts for today")
    }

    @MainActor
    func testCompletingTheLastLessonPublishesPathComplete() throws {
        let context = try makeContext()
        let path = try beginnerPath()
        for lesson in path.lessons.dropLast() {
            context.insert(LessonProgress(lessonId: lesson.id, quizScore: 2))
        }
        try context.save()

        LessonProgressRecorder.complete(lesson: path.lessons.last!, score: 2, context: context, activePath: path, widgetStore: store)

        let published = store.loadStreakData()
        XCTAssertNil(published.nextLessonDayIndex)
        XCTAssertEqual(StreakWidgetStatus(data: published, date: .now), .doneToday)
        XCTAssertEqual(StreakWidgetStatus(data: published, date: Date.now.addingTimeInterval(2 * 86400)), .pathComplete)
    }

    // MARK: - "Done today" turns over at local midnight

    func testCompletedTodayExpiresAtMidnight() {
        let data = WidgetStreakData(streakCount: 4, lastCompletedDate: date(6, 21, 30), nextLessonTitle: "Fearfully made", nextLessonDayIndex: 5)

        XCTAssertTrue(data.isCompleted(on: date(6, 23, 59), calendar: utc))
        XCTAssertFalse(data.isCompleted(on: date(7, 0, 0), calendar: utc), "a lesson finished yesterday must not render as done today")

        let entries = WidgetTimeline.entryDates(from: date(6, 22, 0), calendar: utc)
        XCTAssertEqual(entries, [date(6, 22, 0), date(7, 0, 0)])
        XCTAssertEqual(entries.map { StreakWidgetStatus(data: data, date: $0, calendar: utc) },
                       [.doneToday, .lessonWaiting(day: 5, title: "Fearfully made")])
    }

    func testNextMidnight() {
        XCTAssertEqual(WidgetTimeline.nextMidnight(after: date(6, 14, 30), calendar: utc), date(7, 0, 0))
        XCTAssertEqual(WidgetTimeline.nextMidnight(after: date(7, 0, 0), calendar: utc), date(8, 0, 0))
    }

    // MARK: - Labels

    func testSpokenLabelDoesNotDoubleThePeriod() {
        let verse = DailyVerse(dayIndex: 1, ref: "PSA.23.1", bookAbbrev: "PSA", chapter: 23, verse: 1, bookName: "Psalm",
                               displayRef: "Psalm 23:1", text: "The LORD is my shepherd; I shall lack nothing.")
        XCTAssertEqual(verse.spokenLabel, "Psalm 23:1. The LORD is my shepherd; I shall lack nothing. World English Bible.")
    }
}
