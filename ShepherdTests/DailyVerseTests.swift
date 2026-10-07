import XCTest
@testable import Shepherd

final class DailyVerseTests: XCTestCase {
    func testDailyVerseLoadsFromBundle() {
        let service = DailyVerseService.shared
        XCTAssertGreaterThanOrEqual(service.verses.count, 366)
    }

    func testDeterministicPickSameVerseAllDay() {
        let service = DailyVerseService.shared
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!

        let morningComponents = DateComponents(year: 2026, month: 10, day: 6, hour: 8, minute: 30)
        let afternoonComponents = DateComponents(year: 2026, month: 10, day: 6, hour: 14, minute: 15)
        let nightComponents = DateComponents(year: 2026, month: 10, day: 6, hour: 23, minute: 58)

        guard let morning = cal.date(from: morningComponents),
              let afternoon = cal.date(from: afternoonComponents),
              let night = cal.date(from: nightComponents) else {
            XCTFail("Failed to construct dates")
            return
        }

        let vMorning = service.verse(for: morning, calendar: cal)
        let vAfternoon = service.verse(for: afternoon, calendar: cal)
        let vNight = service.verse(for: night, calendar: cal)

        XCTAssertEqual(vMorning.ref, vAfternoon.ref)
        XCTAssertEqual(vMorning.ref, vNight.ref)
        XCTAssertEqual(vMorning.text, vNight.text)
    }

    func testMidnightRolloverChangesVerse() {
        let service = DailyVerseService.shared
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!

        let beforeMidnight = cal.date(from: DateComponents(year: 2026, month: 10, day: 6, hour: 23, minute: 59, second: 59))!
        let afterMidnight = cal.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 0, minute: 0, second: 1))!

        let vBefore = service.verse(for: beforeMidnight, calendar: cal)
        let vAfter = service.verse(for: afterMidnight, calendar: cal)

        XCTAssertNotEqual(vBefore.ref, vAfter.ref, "Verse must change across midnight")
        XCTAssertNotEqual(vBefore.text, vAfter.text)
    }

    func testLeapYearCoverage() {
        let service = DailyVerseService.shared
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!

        // 2024 is a leap year; Dec 31 is day 366
        let dec31Leap = cal.date(from: DateComponents(year: 2024, month: 12, day: 31, hour: 12, minute: 0))!
        let dayOfYear = cal.ordinality(of: .day, in: .year, for: dec31Leap)
        XCTAssertEqual(dayOfYear, 366)

        let verse = service.verse(for: dec31Leap, calendar: cal)
        XCTAssertFalse(verse.ref.isEmpty)
        XCTAssertFalse(verse.text.isEmpty)
        XCTAssertEqual(verse.ref, service.verses[365].ref)
    }

    func testVerseAttributionAndContent() {
        let service = DailyVerseService.shared
        for verse in service.verses.prefix(10) {
            XCTAssertFalse(verse.text.isEmpty)
            XCTAssertFalse(verse.displayRef.isEmpty)
            XCTAssertFalse(verse.bookAbbrev.isEmpty)
            XCTAssertGreaterThan(verse.chapter, 0)
            XCTAssertGreaterThan(verse.verse, 0)
        }
    }
}
