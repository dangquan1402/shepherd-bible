import XCTest
@testable import Shepherd

/// Premium streak freezes: one per rolling 7 days, at most 2 banked; free users never get or use one.
final class StreakFreezeTests: XCTestCase {

    private var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/New_York")!
        return c
    }()

    private func day(_ d: Int, hour: Int = 9) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: d, hour: hour))!
    }

    func testFirstPremiumUpdateOnlyStartsTheClock() {
        let streak = StreakState(freezesLeft: 1)
        streak.refillFreezes(on: day(1), isPremium: true, calendar: calendar)
        XCTAssertEqual(streak.freezesLeft, 1)
        XCTAssertEqual(streak.freezeRefillAnchor, calendar.startOfDay(for: day(1)))
    }

    func testOneFreezePerSevenDays() {
        let streak = StreakState(freezesLeft: 0, freezeRefillAnchor: calendar.startOfDay(for: day(1)))
        streak.refillFreezes(on: day(7, hour: 23), isPremium: true, calendar: calendar)
        XCTAssertEqual(streak.freezesLeft, 0, "6 days is not a week")
        streak.refillFreezes(on: day(8, hour: 0), isPremium: true, calendar: calendar)
        XCTAssertEqual(streak.freezesLeft, 1, "7 days earns one freeze")
        streak.refillFreezes(on: day(8, hour: 20), isPremium: true, calendar: calendar)
        XCTAssertEqual(streak.freezesLeft, 1, "the same week does not earn twice")
        XCTAssertEqual(streak.freezeRefillAnchor, calendar.startOfDay(for: day(8)))
    }

    func testCadenceIsKeptWhenARefillIsLate() {
        // Last refilled on day 1; next opened on day 11: one freeze, and the next is due on day 15, not day 18.
        let streak = StreakState(freezesLeft: 0, freezeRefillAnchor: calendar.startOfDay(for: day(1)))
        streak.refillFreezes(on: day(11), isPremium: true, calendar: calendar)
        XCTAssertEqual(streak.freezesLeft, 1)
        streak.refillFreezes(on: day(15), isPremium: true, calendar: calendar)
        XCTAssertEqual(streak.freezesLeft, 2)
    }

    func testBankIsCappedAtTwo() {
        let streak = StreakState(freezesLeft: 0, freezeRefillAnchor: calendar.startOfDay(for: day(1)))
        streak.refillFreezes(on: day(29), isPremium: true, calendar: calendar) // four weeks
        XCTAssertEqual(streak.freezesLeft, StreakState.maxFreezes)
        XCTAssertEqual(StreakState.maxFreezes, 2)
        // Weeks spent at the cap are not saved up: spend both, and the next one is a week away.
        XCTAssertTrue(streak.consumeFreeze(isPremium: true))
        XCTAssertTrue(streak.consumeFreeze(isPremium: true))
        XCTAssertFalse(streak.consumeFreeze(isPremium: true), "an empty bank cannot be used")
        streak.refillFreezes(on: day(30), isPremium: true, calendar: calendar)
        XCTAssertEqual(streak.freezesLeft, 0)
    }

    func testFreeUsersNeitherEarnNorUseFreezes() {
        let streak = StreakState(freezesLeft: 1, freezeRefillAnchor: calendar.startOfDay(for: day(1)))
        streak.refillFreezes(on: day(29), isPremium: false, calendar: calendar)
        XCTAssertEqual(streak.freezesLeft, 1, "free users do not earn freezes")
        XCTAssertFalse(streak.consumeFreeze(isPremium: false))
        XCTAssertEqual(streak.freezesLeft, 1)
    }

    /// End to end through markCompleted: a Premium user who used their freeze gets a new one a
    /// week later, and it saves the streak across one missed day.
    func testRefilledFreezeSavesAMissedDay() {
        let now = Date()
        let cal = Calendar.current
        let streak = StreakState(current: 10, best: 10, lastCompletedDate: now, freezesLeft: 0,
                                 freezeRefillAnchor: cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: now)))
        let twoDaysLater = cal.date(byAdding: .day, value: 2, to: now)!
        streak.markCompleted(on: twoDaysLater, isPremium: true)
        XCTAssertEqual(streak.current, 11, "the freeze earned this week covers the missed day")
        XCTAssertEqual(streak.freezesLeft, 0, "and is used up")

        let free = StreakState(current: 10, best: 10, lastCompletedDate: now, freezesLeft: 0,
                               freezeRefillAnchor: cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: now)))
        free.markCompleted(on: twoDaysLater, isPremium: false)
        XCTAssertEqual(free.current, 1, "free users' streak resets after a missed day")
    }
}
