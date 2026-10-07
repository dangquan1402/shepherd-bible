import XCTest
@testable import Shepherd

/// The App Store rating prompt: each trigger rule on its own.
final class ReviewPromptTests: XCTestCase {

    private func completed(day: Int, score: Int = 3, of total: Int = 3, oldXP: Int = 24, newXP: Int = 37, replay: Bool = false) -> ReviewMoment {
        .lessonCompleted(dayIndex: day, score: score, totalQuestions: total, oldXP: oldXP, newXP: newXP, wasAlreadyCompleted: replay)
    }

    private func asks(_ moment: ReviewMoment, last: String? = nil) -> Bool {
        ReviewPromptPolicy.shouldRequest(moment, currentVersion: "1.0.0", lastPromptedVersion: last)
    }

    func testPerfectDay3Asks() {
        XCTAssertTrue(asks(completed(day: 3)))
        XCTAssertTrue(asks(completed(day: 3, score: 2, of: 2)), "Day 3 of any path, whatever its length of quiz")
    }

    func testLambReachingStage2Asks() {
        // 39 XP -> 52 XP crosses into Stage 2 (50 XP) on Day 4.
        XCTAssertTrue(asks(completed(day: 4, oldXP: 39, newXP: 52)))
    }

    func testOtherDaysDoNotAsk() {
        XCTAssertFalse(asks(completed(day: 1, oldXP: 0, newXP: 13)))
        XCTAssertFalse(asks(completed(day: 4, oldXP: 39, newXP: 49)), "still Stage 1")
        XCTAssertFalse(asks(completed(day: 9, oldXP: 52, newXP: 65)), "already Stage 2 before this lesson")
    }

    func testNeverAfterAWrongAnswer() {
        XCTAssertFalse(asks(completed(day: 3, score: 2, of: 3)))
        XCTAssertFalse(asks(completed(day: 4, score: 2, of: 3, oldXP: 39, newXP: 51)))
        XCTAssertFalse(asks(completed(day: 3, score: 0, of: 0)), "a lesson without a quiz is not a perfect quiz")
    }

    func testAtMostOncePerVersion() {
        XCTAssertFalse(asks(completed(day: 3), last: "1.0.0"))
        XCTAssertTrue(asks(completed(day: 3), last: "0.9.0"), "a new version may ask again")
    }

    func testNeverOnLaunchOrPaywallDismissal() {
        XCTAssertFalse(asks(.appLaunch))
        XCTAssertFalse(asks(.paywallDismissed))
    }

    func testReplayingALessonDoesNotAsk() {
        XCTAssertFalse(asks(completed(day: 3, replay: true)))
    }

    func testPrompterRecordsTheVersion() {
        let name = "ReviewPromptTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        XCTAssertFalse(ReviewPrompter.shouldRequest(completed(day: 2), defaults: defaults, version: "1.0.0"))
        XCTAssertNil(defaults.string(forKey: ReviewPrompter.promptedVersionKey), "a 'no' must not use up the version")
        XCTAssertTrue(ReviewPrompter.shouldRequest(completed(day: 3), defaults: defaults, version: "1.0.0"))
        XCTAssertFalse(ReviewPrompter.shouldRequest(completed(day: 4, oldXP: 39, newXP: 52), defaults: defaults, version: "1.0.0"))
        XCTAssertTrue(ReviewPrompter.shouldRequest(completed(day: 3), defaults: defaults, version: "1.1.0"))
    }
}
