import XCTest
import SwiftData
import UIKit
@testable import Shepherd

final class ShepherdTests: XCTestCase {

    // MARK: - 1. XP Calculation (XP = 10 + score) & Progress Recorder
    @MainActor
    func testXPEarnedCalculation() throws {
        // Test production pure function
        XCTAssertEqual(Progression.xpEarned(score: 0), 10, "0/2 correct must yield 10 XP")
        XCTAssertEqual(Progression.xpEarned(score: 1), 11, "1/2 correct must yield 11 XP")
        XCTAssertEqual(Progression.xpEarned(score: 2), 12, "2/2 correct must yield 12 XP")

        // Test production LessonProgressRecorder against an in-memory ModelContainer
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Companion.self, StreakState.self, LessonProgress.self, configurations: config)
        let context = ModelContext(container)

        let companion = Companion(name: "Barnaby", stage: 1, xp: 0)
        let streak = StreakState()
        context.insert(companion)
        context.insert(streak)
        try context.save()

        ContentStore.shared.loadIfNeeded()
        guard let lesson = ContentStore.shared.paths.first?.lessons.first else {
            XCTFail("Missing day 1 lesson in ContentStore")
            return
        }

        let res0 = LessonProgressRecorder.complete(lesson: lesson, score: 2, context: context)
        XCTAssertEqual(res0.xpAwarded, 12, "Score 2 should award 12 XP delta")
        XCTAssertEqual(companion.xp, 12, "Companion XP should increase by 12")
        XCTAssertEqual(res0.wasAlreadyCompleted, false)
    }

    // MARK: - 2. Stage Progression (stage = max(1, min(5, 1 + xp / 50)))
    func testStageProgression() {
        XCTAssertEqual(Progression.stage(for: 0), 1)
        XCTAssertEqual(Progression.stage(for: 49), 1)
        XCTAssertEqual(Progression.stage(for: 50), 2)
        XCTAssertEqual(Progression.stage(for: 99), 2)
        XCTAssertEqual(Progression.stage(for: 100), 3)
        XCTAssertEqual(Progression.stage(for: 150), 4)
        XCTAssertEqual(Progression.stage(for: 200), 5)
        XCTAssertEqual(Progression.stage(for: 350), 5, "Stage must cap at 5")

        let companion = Companion(name: "Barnaby", stage: 1, xp: 0)
        XCTAssertEqual(companion.stage, 1)

        companion.addXP(49)
        XCTAssertEqual(companion.xp, 49)
        XCTAssertEqual(companion.stage, 1)

        companion.addXP(1)
        XCTAssertEqual(companion.xp, 50)
        XCTAssertEqual(companion.stage, 2)

        companion.addXP(50)
        XCTAssertEqual(companion.xp, 100)
        XCTAssertEqual(companion.stage, 3)

        companion.addXP(50)
        XCTAssertEqual(companion.xp, 150)
        XCTAssertEqual(companion.stage, 4)

        companion.addXP(50)
        XCTAssertEqual(companion.xp, 200)
        XCTAssertEqual(companion.stage, 5)

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

        // Same day completion (idempotent)
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

    // MARK: - 3b. Streak Freeze Protection on 1-Day Gap
    func testStreakFreezeProtection() {
        let calendar = Calendar.current
        let now = Date()

        // Branch 1: Premium user with freeze available -> 1-day gap preserves streak
        let premiumStreak = StreakState(current: 5, best: 5, freezesLeft: 1)
        premiumStreak.lastCompletedDate = now

        guard let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: now) else {
            XCTFail("Failed to compute dayAfterTomorrow")
            return
        }

        // 1-day gap (tomorrow was missed)
        premiumStreak.markCompleted(on: dayAfterTomorrow, isPremium: true)
        XCTAssertEqual(premiumStreak.current, 6, "Premium user with freeze should preserve and increment streak on 1-day gap")
        XCTAssertEqual(premiumStreak.freezesLeft, 0, "Freeze should be consumed")

        // Branch 2: Free user -> 1-day gap resets streak to 1 even if freezesLeft > 0
        let freeStreak = StreakState(current: 5, best: 5, freezesLeft: 1)
        freeStreak.lastCompletedDate = now

        freeStreak.markCompleted(on: dayAfterTomorrow, isPremium: false)
        XCTAssertEqual(freeStreak.current, 1, "Free user on 1-day gap must reset streak to 1")
        XCTAssertEqual(freeStreak.freezesLeft, 1, "Free user cannot consume streak freeze")
    }

    // MARK: - 4. Explain and Answering Verse Selection (M5 Rule) with Real Content
    @MainActor
    func testExplainAndVerseSelectionRule() async throws {
        let store = ContentStore.shared
        await store.ensureBibleLoaded()
        let day1Lesson = try XCTUnwrap(store.path(id: "beginner-30")?.lessons.first, "Missing day 1 lesson")
        XCTAssertGreaterThanOrEqual(day1Lesson.quiz.count, 2)

        // Question 1: "Who created the heavens and the earth?" -> "God", proved by Genesis 1:1
        let q1 = day1Lesson.quiz[0]
        let v1 = try XCTUnwrap(QuizRules.answeringVerse(for: q1, in: day1Lesson) { store.verse(ref: $0) })
        XCTAssertEqual(v1.ref, "GEN.1.1", "Question 1 answering verse must be GEN.1.1")
        XCTAssertTrue(v1.text.localizedCaseInsensitiveContains("God"))

        // Question 2: "What did God say first?" -> "Let there be light", proved by Genesis 1:3
        let q2 = day1Lesson.quiz[1]
        let v2 = try XCTUnwrap(QuizRules.answeringVerse(for: q2, in: day1Lesson) { store.verse(ref: $0) })
        XCTAssertEqual(v2.ref, "GEN.1.3", "Question 2 answering verse must be GEN.1.3")
        XCTAssertTrue(v2.text.localizedCaseInsensitiveContains("Let there be light"))
    }

    // MARK: - 5. Onboarding Answers Persistence via OnboardingStore
    @MainActor
    func testOnboardingAnswersPersistence() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: UserProfile.self, Companion.self, StreakState.self, EntitlementState.self, configurations: config)
        let context = ModelContext(container)

        // Seed existing companion as SeedData does
        let initialCompanion = Companion(name: "DefaultLamb", stage: 1, xp: 0)
        context.insert(initialCompanion)
        try context.save()

        // Test with custom name "Pip"
        OnboardingStore.complete(
            goal: "peace",
            experience: "some",
            minutes: 10,
            name: "Pip",
            context: context
        )

        let profiles = try context.fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(profiles.count, 1)
        let profile = try XCTUnwrap(profiles.first)
        XCTAssertEqual(profile.goal, "peace")
        XCTAssertEqual(profile.experienceLevel, "some")
        XCTAssertEqual(profile.dailyMinutes, 10)
        XCTAssertTrue(profile.hasCompletedOnboarding)

        // Existing companion should be renamed to "Pip", not duplicated
        let companions = try context.fetch(FetchDescriptor<Companion>())
        XCTAssertEqual(companions.count, 1)
        XCTAssertEqual(companions.first?.name, "Pip")

        // Test fallback: empty name defaults to "Lamb"
        OnboardingStore.complete(
            goal: "grow_daily",
            experience: "beginner",
            minutes: 5,
            name: "",
            context: context
        )
        let updatedCompanions = try context.fetch(FetchDescriptor<Companion>())
        XCTAssertEqual(updatedCompanions.count, 1)
        XCTAssertEqual(updatedCompanions.first?.name, "Lamb")
    }

    // MARK: - 6. Entitlement Gating with Production Entitlements & StreakState
    func testEntitlementGating() {
        for feature in PremiumFeature.allCases {
            XCTAssertFalse(
                Entitlements.isUnlocked(feature, isPremium: false),
                "\(feature) must be locked for free users"
            )
            XCTAssertTrue(
                Entitlements.isUnlocked(feature, isPremium: true),
                "\(feature) must be unlocked for premium users"
            )
        }

        // Test streak freeze gating in StreakState
        let streak = StreakState(freezesLeft: 2)
        XCTAssertFalse(streak.consumeFreeze(isPremium: false), "Free user cannot consume streak freeze")
        XCTAssertEqual(streak.freezesLeft, 2, "Freezes count must remain unchanged")

        XCTAssertTrue(streak.consumeFreeze(isPremium: true), "Premium user can consume streak freeze")
        XCTAssertEqual(streak.freezesLeft, 1, "Freezes count must decrement")
    }

    // MARK: - 7. SVG Path Parser Subpath Regression (B1)
    func testSVGPathParserSubpathRegression() {
        let path = SVGPathParser.parse(geometry: "M10 10l1 0 0 1z m5 0l1 0 0 1z")
        XCTAssertEqual(path.boundingRect, CGRect(x: 10, y: 10, width: 6, height: 1))
    }

    // MARK: - 7b. Lamb geometry: every variant loads and every fill resolves to a theme colour
    func testLambVariantsLoadAndEveryFillResolves() {
        let store = LambVariantStore.shared
        var fillKeys = Set<String>()
        for stage in 1...5 {
            for expression in LambExpression.allCases {
                guard let variant = store.variant(stage: stage, expression: expression) else {
                    return XCTFail("missing lamb S\(stage)/\(expression.rawValue)")
                }
                XCTAssertEqual(variant.expression, expression.rawValue, "S\(stage) fell back instead of loading \(expression.rawValue)")
                XCTAssertFalse(variant.layers.isEmpty)
                XCTAssertTrue(variant.layers.contains { $0.name == "Eyes" }, "S\(stage)/\(expression.rawValue) has no Eyes layer")
                fillKeys.formUnion(variant.layers.map(\.fillKey))
            }
        }
        for key in ["S1/Happy", "S1/Encouraging", "S1/Idle", "S2/Idle", "S3/Idle", "S4/Idle", "S5/Idle"] {
            guard let avatar = store.avatar(key: key) else { return XCTFail("missing avatar \(key)") }
            fillKeys.formUnion(avatar.layers.map(\.fillKey))
        }
        XCTAssertNotNil(store.glyphPath, "tab glyph missing")
        for key in fillKeys.sorted() {
            XCTAssertNotNil(LambVariantStore.color(forKey: key), "lamb fill key '\(key)' has no theme colour (it would render in the accent)")
        }
        // The eye whites blink with the pupils (Flock lamb: white sclera on a dark face)
        XCTAssertTrue(LambVariantStore.blinkLayerNames.isSuperset(of: ["EyeWhites", "Eyes", "Catchlights"]))
    }

    // MARK: - 8. No XP Farming on Retaking Completed Lesson (M7)
    @MainActor
    func testNoXPFarmingOnRetake() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Companion.self, StreakState.self, LessonProgress.self, configurations: config)
        let context = ModelContext(container)

        let companion = Companion(name: "Barnaby", stage: 1, xp: 0)
        let streak = StreakState()
        context.insert(companion)
        context.insert(streak)
        try context.save()

        ContentStore.shared.loadIfNeeded()
        guard let lesson = ContentStore.shared.paths.first?.lessons.first else {
            XCTFail("Missing day 1 lesson in ContentStore")
            return
        }

        // First completion awards XP
        let first = LessonProgressRecorder.complete(lesson: lesson, score: 2, context: context)
        XCTAssertFalse(first.wasAlreadyCompleted)
        XCTAssertEqual(first.xpAwarded, 12)
        XCTAssertEqual(companion.xp, 12)

        // Retaking the completed lesson MUST NOT award XP again
        let second = LessonProgressRecorder.complete(lesson: lesson, score: 2, context: context)
        XCTAssertTrue(second.wasAlreadyCompleted)
        XCTAssertEqual(second.xpAwarded, 0, "Retaking lesson must award 0 XP")
        XCTAssertEqual(companion.xp, 12, "Companion XP must not increase on retake")
    }

    // MARK: - Brand name (the app was renamed from Shepherd; Swift module and bundle id keep the old name)
    func testUserVisibleNameIsPasture() throws {
        XCTAssertEqual(Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String, "Pasture")

        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "Shepherd", withExtension: "storekit"))
        let config = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        let groups = try XCTUnwrap(config["subscriptionGroups"] as? [[String: Any]])
        var names: [String] = []
        for group in groups {
            names.append(try XCTUnwrap(group["name"] as? String))
            let groupLocs = group["localizations"] as? [[String: Any]] ?? []
            let subLocs = (group["subscriptions"] as? [[String: Any]] ?? []).flatMap { $0["localizations"] as? [[String: Any]] ?? [] }
            names += (groupLocs + subLocs).compactMap { $0["displayName"] as? String }
        }
        XCTAssertEqual(names.count, 4)
        for name in names {
            XCTAssertTrue(name.hasPrefix("Pasture Premium"), name)
        }
    }

    func testLegalAndSupportURLsPointAtPastureSite() {
        XCTAssertEqual(ShepherdConstants.legalAndSupportURLs.count, 3)
        for url in ShepherdConstants.legalAndSupportURLs {
            XCTAssertEqual(url.scheme, "https", url.absoluteString)
            XCTAssertEqual(url.host, "dangquan1402.github.io", url.absoluteString)
            XCTAssertTrue(url.path.hasPrefix("/pasture/"), url.absoluteString)
            XCTAssertFalse(url.absoluteString.contains("shepherd.bible"), url.absoluteString)
        }
    }

    // MARK: - Contrast: quiz letter badge (WCAG AA, 4.5:1 for 16 pt bold text)
    func testChoiceLetterBadgeMeetsAA() throws {
        func luminance(_ c: UIColor) -> Double {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            c.getRed(&r, green: &g, blue: &b, alpha: &a)
            func lin(_ v: CGFloat) -> Double {
                let v = Double(v)
                return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
        }
        // The probe must see the dark variant, or a dark-only failure could never show up.
        let canvasLight = try XCTUnwrap(UIColor(named: "CanvasBg", in: .main, compatibleWith: nil)).resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        let canvasDark = try XCTUnwrap(UIColor(named: "CanvasBg", in: .main, compatibleWith: nil)).resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        XCTAssertLessThan(luminance(canvasDark), 0.05)
        XCTAssertGreaterThan(luminance(canvasLight), 0.9)

        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            for state in [ChoiceRowState.neutral, .selected, .correct, .revealed, .wrong] {
                let names = state.letterBadgeColorNames
                // resolvedColor: a named colour is dynamic, and getRed would otherwise read the light variant.
                let text = try XCTUnwrap(UIColor(named: names.text, in: .main, compatibleWith: traits), names.text).resolvedColor(with: traits)
                let fill = try XCTUnwrap(UIColor(named: names.fill, in: .main, compatibleWith: traits), names.fill).resolvedColor(with: traits)
                let l = [luminance(text), luminance(fill)].sorted(by: >)
                let ratio = (l[0] + 0.05) / (l[1] + 0.05)
                XCTAssertGreaterThanOrEqual(ratio, 4.5, "\(state) badge \(names.text) on \(names.fill), \(style == .dark ? "dark" : "light"): \(String(format: "%.2f", ratio))")
            }
        }
    }
}
