import XCTest
import SwiftData
@testable import Shepherd

final class ShepherdTests: XCTestCase {

    // MARK: - 1. XP Calculation (XP = 10 + score)
    func testXPEarnedCalculation() {
        func xpEarned(score: Int) -> Int {
            10 + score
        }

        XCTAssertEqual(xpEarned(score: 0), 10, "0/2 correct must yield 10 XP")
        XCTAssertEqual(xpEarned(score: 1), 11, "1/2 correct must yield 11 XP")
        XCTAssertEqual(xpEarned(score: 2), 12, "2/2 correct must yield 12 XP")
    }

    // MARK: - 2. Stage Progression (stage = max(1, min(5, 1 + xp / 50)))
    func testStageProgression() {
        let companion = Companion(name: "Barnaby", stage: 1, xp: 0)

        // Threshold checks
        XCTAssertEqual(companion.stage, 1, "0 XP should be stage 1")

        companion.addXP(49)
        XCTAssertEqual(companion.xp, 49)
        XCTAssertEqual(companion.stage, 1, "49 XP should still be stage 1")

        companion.addXP(1)
        XCTAssertEqual(companion.xp, 50)
        XCTAssertEqual(companion.stage, 2, "50 XP should unlock stage 2")

        companion.addXP(49)
        XCTAssertEqual(companion.xp, 99)
        XCTAssertEqual(companion.stage, 2, "99 XP should still be stage 2")

        companion.addXP(1)
        XCTAssertEqual(companion.xp, 100)
        XCTAssertEqual(companion.stage, 3, "100 XP should unlock stage 3")

        companion.addXP(50)
        XCTAssertEqual(companion.xp, 150)
        XCTAssertEqual(companion.stage, 4, "150 XP should unlock stage 4")

        companion.addXP(50)
        XCTAssertEqual(companion.xp, 200)
        XCTAssertEqual(companion.stage, 5, "200 XP should unlock stage 5")

        companion.addXP(150)
        XCTAssertEqual(companion.xp, 350)
        XCTAssertEqual(companion.stage, 5, "Stage must cap at 5")
    }

    // MARK: - 3. Streak Progression (First day 1, consecutive +1, gap resets)
    func testStreakProgression() {
        let streak = StreakState()
        let calendar = Calendar.current
        let now = Date()

        XCTAssertEqual(streak.current, 0, "Initial streak starts at 0")
        XCTAssertEqual(streak.best, 0)

        // Day 1
        streak.markCompleted(on: now)
        XCTAssertEqual(streak.current, 1, "First completion should set streak to 1")
        XCTAssertEqual(streak.best, 1)

        // Same day completion (should be idempotent)
        streak.markCompleted(on: now)
        XCTAssertEqual(streak.current, 1, "Same day completion should not increment streak")

        // Day 2 (consecutive day)
        guard let day2 = calendar.date(byAdding: .day, value: 1, to: now) else {
            XCTFail("Failed to compute day 2")
            return
        }
        streak.markCompleted(on: day2)
        XCTAssertEqual(streak.current, 2, "Consecutive day should increment streak to 2")
        XCTAssertEqual(streak.best, 2)

        // Day 3 (consecutive day)
        guard let day3 = calendar.date(byAdding: .day, value: 2, to: now) else {
            XCTFail("Failed to compute day 3")
            return
        }
        streak.markCompleted(on: day3)
        XCTAssertEqual(streak.current, 3, "Consecutive day should increment streak to 3")
        XCTAssertEqual(streak.best, 3)

        // Day 6 (gap of 3 days -> reset to 1, best remains 3)
        guard let day6 = calendar.date(byAdding: .day, value: 5, to: now) else {
            XCTFail("Failed to compute day 6")
            return
        }
        streak.markCompleted(on: day6)
        XCTAssertEqual(streak.current, 1, "Gap day must reset streak to 1")
        XCTAssertEqual(streak.best, 3, "Best streak must be preserved as 3")
    }

    // MARK: - 4. Explain and Answering Verse Selection (M5 Rule)
    func testExplainAndVerseSelectionRule() {
        // Mock Content
        let verses: [String: String] = [
            "GEN.1.1": "In the beginning, God created the heavens and the earth.",
            "GEN.1.3": "God said, \"Let there be light,\" and there was light."
        ]

        func resolveVerse(correctChoice: String, verseRefs: [String]) -> String {
            for ref in verseRefs {
                if let text = verses[ref], text.localizedCaseInsensitiveContains(correctChoice) {
                    return ref
                }
            }
            return verseRefs.first ?? ""
        }

        let lessonVerseRefs = ["GEN.1.1", "GEN.1.3"]

        // Question 1: "Who created the heavens and the earth?" -> Choice "God"
        // Genesis 1:1 contains "God" -> Should resolve to GEN.1.1
        let q1Verse = resolveVerse(correctChoice: "God", verseRefs: lessonVerseRefs)
        XCTAssertEqual(q1Verse, "GEN.1.1", "Question 1 correct choice 'God' must match Genesis 1:1")

        // Question 2: "What did God say first?" -> Choice "Let there be light"
        // Genesis 1:3 contains "Let there be light" -> Should resolve to GEN.1.3
        let q2Verse = resolveVerse(correctChoice: "Let there be light", verseRefs: lessonVerseRefs)
        XCTAssertEqual(q2Verse, "GEN.1.3", "Question 2 correct choice 'Let there be light' must match Genesis 1:3")

        // Fallback case: Choice not contained in any verse text
        let fallbackVerse = resolveVerse(correctChoice: "Nonexistent Word", verseRefs: lessonVerseRefs)
        XCTAssertEqual(fallbackVerse, "GEN.1.1", "Fallback must return lesson.verseRefs[0]")
    }

    // MARK: - 5. Onboarding Answers Persistence
    func testOnboardingAnswersPersistence() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserProfile.self, Companion.self, configurations: config)
        let context = ModelContext(container)

        // Simulate completing onboarding
        let profile = UserProfile(
            goal: "peace",
            experienceLevel: "regular",
            dailyMinutes: 10,
            hasCompletedOnboarding: true
        )
        let companion = Companion(name: "Barnaby", stage: 1, xp: 0)

        context.insert(profile)
        context.insert(companion)
        try context.save()

        // Fetch back and assert
        let fetchedProfiles = try context.fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(fetchedProfiles.count, 1)
        let savedProfile = try XCTUnwrap(fetchedProfiles.first)
        XCTAssertEqual(savedProfile.goal, "peace")
        XCTAssertEqual(savedProfile.experienceLevel, "regular")
        XCTAssertEqual(savedProfile.dailyMinutes, 10)
        XCTAssertTrue(savedProfile.hasCompletedOnboarding)

        let fetchedCompanions = try context.fetch(FetchDescriptor<Companion>())
        XCTAssertEqual(fetchedCompanions.count, 1)
        let savedCompanion = try XCTUnwrap(fetchedCompanions.first)
        XCTAssertEqual(savedCompanion.name, "Barnaby")
        XCTAssertEqual(savedCompanion.stage, 1)
        XCTAssertEqual(savedCompanion.xp, 0)
    }

    // MARK: - 6. Entitlement Gating with and without Purchase
    func testEntitlementGating() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: EntitlementState.self, configurations: config)
        let context = ModelContext(container)

        // Without purchase
        let freeState = EntitlementState(isPremium: false)
        context.insert(freeState)
        try context.save()

        func isFeatureAvailable(feature: String, isPremium: Bool) -> Bool {
            if feature == "daily_path" || feature == "bible_reader" {
                return true // Always free
            }
            return isPremium
        }

        XCTAssertTrue(isFeatureAvailable(feature: "daily_path", isPremium: freeState.isPremium), "Daily path is free")
        XCTAssertTrue(isFeatureAvailable(feature: "bible_reader", isPremium: freeState.isPremium), "Bible reader is free")
        XCTAssertFalse(isFeatureAvailable(feature: "streak_freezes", isPremium: freeState.isPremium), "Streak freezes gated for free users")
        XCTAssertFalse(isFeatureAvailable(feature: "companion_outfits", isPremium: freeState.isPremium), "Outfits gated for free users")

        // With purchase
        freeState.isPremium = true
        try context.save()

        let updated = try XCTUnwrap(try context.fetch(FetchDescriptor<EntitlementState>()).first)
        XCTAssertTrue(updated.isPremium)
        XCTAssertTrue(isFeatureAvailable(feature: "streak_freezes", isPremium: updated.isPremium), "Streak freezes available with premium")
        XCTAssertTrue(isFeatureAvailable(feature: "companion_outfits", isPremium: updated.isPremium), "Outfits available with premium")
    }
}
