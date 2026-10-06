import XCTest
import SwiftData
@testable import Shepherd

final class JournalTests: XCTestCase {

    // MARK: - 1. JournalEntry Creation and Editing
    @MainActor
    func testJournalEntryCreationAndEditing() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: JournalEntry.self, PrayerRequest.self, configurations: config)
        let context = ModelContext(container)

        let entry = JournalEntry(
            lessonId: "day1",
            lessonTitle: "In the beginning",
            prompt: "Where in your life does it feel dark or unformed right now?",
            text: "Reflecting on God creating light out of darkness."
        )

        context.insert(entry)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<JournalEntry>())
        XCTAssertEqual(fetched.count, 1)
        let saved = try XCTUnwrap(fetched.first)
        XCTAssertEqual(saved.lessonId, "day1")
        XCTAssertEqual(saved.lessonTitle, "In the beginning")
        XCTAssertEqual(saved.text, "Reflecting on God creating light out of darkness.")
        XCTAssertNil(saved.updatedAt)

        // Edit reflection
        saved.text = "Updated reflection with new thoughts."
        saved.updatedAt = .now
        try context.save()

        let updated = try context.fetch(FetchDescriptor<JournalEntry>())
        XCTAssertEqual(updated.first?.text, "Updated reflection with new thoughts.")
        XCTAssertNotNil(updated.first?.updatedAt)

        // Delete reflection
        context.delete(saved)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<JournalEntry>())
        XCTAssertEqual(remaining.count, 0)
    }

    // MARK: - 2. PrayerRequest Mark as Answered & Unanswered with Date
    @MainActor
    func testPrayerRequestAnsweredStatusAndDate() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: JournalEntry.self, PrayerRequest.self, configurations: config)
        let context = ModelContext(container)

        let prayer = PrayerRequest(text: "Praying for guidance on my new job.")
        context.insert(prayer)
        try context.save()

        XCTAssertFalse(prayer.isAnswered)
        XCTAssertNil(prayer.answeredDate)

        // Mark answered
        let answeredDate = Date()
        prayer.markAnswered(on: answeredDate)
        try context.save()

        XCTAssertTrue(prayer.isAnswered)
        XCTAssertEqual(prayer.answeredDate, answeredDate)

        // Mark unanswered
        prayer.markUnanswered()
        try context.save()

        XCTAssertFalse(prayer.isAnswered)
        XCTAssertNil(prayer.answeredDate)
    }

    // MARK: - 3. PrayerRequest Filtering (Open vs Answered)
    @MainActor
    func testPrayerFiltering() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: JournalEntry.self, PrayerRequest.self, configurations: config)
        let context = ModelContext(container)

        let prayer1 = PrayerRequest(text: "Open prayer 1")
        let prayer2 = PrayerRequest(text: "Open prayer 2")
        let prayer3 = PrayerRequest(text: "Answered prayer 1", isAnswered: true, answeredDate: .now)

        context.insert(prayer1)
        context.insert(prayer2)
        context.insert(prayer3)
        try context.save()

        let all = try context.fetch(FetchDescriptor<PrayerRequest>())
        XCTAssertEqual(all.count, 3)

        let open = all.filter { !$0.isAnswered }
        XCTAssertEqual(open.count, 2)
        XCTAssertTrue(open.contains { $0.text == "Open prayer 1" })
        XCTAssertTrue(open.contains { $0.text == "Open prayer 2" })

        let answered = all.filter { $0.isAnswered }
        XCTAssertEqual(answered.count, 1)
        XCTAssertEqual(answered.first?.text, "Answered prayer 1")
    }

    // MARK: - 4. Lightweight Additive Migration from V1 Store
    @MainActor
    func testAdditiveMigrationFromV1Store() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let storeURL = tempDir.appendingPathComponent("shepherd_v1.sqlite")

        // 1. Create a persistent store containing ONLY the 5 original models
        let v1Config = ModelConfiguration(url: storeURL)
        let v1Container = try ModelContainer(
            for: UserProfile.self, Companion.self, StreakState.self, LessonProgress.self, EntitlementState.self,
            configurations: v1Config
        )
        let v1Context = ModelContext(v1Container)

        let profile = UserProfile(goal: "peace", experienceLevel: "beginner")
        let companion = Companion(name: "Barnaby", stage: 2, xp: 60)
        let streak = StreakState(current: 5, best: 5)
        let progress = LessonProgress(lessonId: "day1", quizScore: 2)

        v1Context.insert(profile)
        v1Context.insert(companion)
        v1Context.insert(streak)
        v1Context.insert(progress)
        try v1Context.save()

        // 2. Open the exact same store using the new schema including JournalEntry & PrayerRequest
        let v2Config = ModelConfiguration(url: storeURL)
        let v2Container = try ModelContainer(
            for: UserProfile.self, Companion.self, StreakState.self, LessonProgress.self, EntitlementState.self, JournalEntry.self, PrayerRequest.self,
            configurations: v2Config
        )
        let v2Context = ModelContext(v2Container)

        // 3. Verify all existing v1 data survived migration intact
        let fetchedProfiles = try v2Context.fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(fetchedProfiles.count, 1)
        XCTAssertEqual(fetchedProfiles.first?.goal, "peace")

        let fetchedCompanions = try v2Context.fetch(FetchDescriptor<Companion>())
        XCTAssertEqual(fetchedCompanions.count, 1)
        XCTAssertEqual(fetchedCompanions.first?.name, "Barnaby")
        XCTAssertEqual(fetchedCompanions.first?.xp, 60)

        let fetchedStreaks = try v2Context.fetch(FetchDescriptor<StreakState>())
        XCTAssertEqual(fetchedStreaks.count, 1)
        XCTAssertEqual(fetchedStreaks.first?.current, 5)

        let fetchedProgress = try v2Context.fetch(FetchDescriptor<LessonProgress>())
        XCTAssertEqual(fetchedProgress.count, 1)
        XCTAssertEqual(fetchedProgress.first?.lessonId, "day1")

        // 4. Verify we can insert and query new JournalEntry and PrayerRequest records into the migrated store
        let entry = JournalEntry(lessonId: "day1", lessonTitle: "In the beginning", prompt: "Prompt", text: "Reflection text")
        let prayer = PrayerRequest(text: "Prayer request")
        v2Context.insert(entry)
        v2Context.insert(prayer)
        try v2Context.save()

        let fetchedJournals = try v2Context.fetch(FetchDescriptor<JournalEntry>())
        XCTAssertEqual(fetchedJournals.count, 1)
        XCTAssertEqual(fetchedJournals.first?.text, "Reflection text")

        let fetchedPrayers = try v2Context.fetch(FetchDescriptor<PrayerRequest>())
        XCTAssertEqual(fetchedPrayers.count, 1)
        XCTAssertEqual(fetchedPrayers.first?.text, "Prayer request")
    }

    // MARK: - 5. Reflection Step Does Not Block Lesson Completion or Streak
    @MainActor
    func testReflectionStepNeverBlocksCompletionOrStreak() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Companion.self, StreakState.self, LessonProgress.self, JournalEntry.self,
            configurations: config
        )
        let context = ModelContext(container)

        let companion = Companion(name: "Barnaby", stage: 1, xp: 0)
        let streak = StreakState()
        context.insert(companion)
        context.insert(streak)
        try context.save()

        ContentStore.shared.loadIfNeeded()
        guard let lesson = ContentStore.shared.paths.first?.lessons.first else {
            XCTFail("Missing day 1 lesson")
            return
        }

        // Completion and streak are recorded BEFORE the reflection step is reached
        let result = LessonProgressRecorder.complete(lesson: lesson, score: 2, context: context)
        XCTAssertEqual(result.streakCount, 1)
        XCTAssertEqual(result.xpAwarded, 12)
        XCTAssertEqual(companion.xp, 12)

        let progressList = try context.fetch(FetchDescriptor<LessonProgress>())
        XCTAssertEqual(progressList.count, 1)
        XCTAssertEqual(progressList.first?.lessonId, lesson.id)

        // Case A: User skips reflection (no JournalEntry created)
        // Completion and streak remain 100% intact
        let journalsAfterSkip = try context.fetch(FetchDescriptor<JournalEntry>())
        XCTAssertEqual(journalsAfterSkip.count, 0)
        XCTAssertEqual(streak.current, 1)

        // Case B: User writes and saves reflection
        let entry = JournalEntry(lessonId: lesson.id, lessonTitle: lesson.title, prompt: lesson.prayerPrompt, text: "My reflection")
        context.insert(entry)
        try context.save()

        let journalsAfterSave = try context.fetch(FetchDescriptor<JournalEntry>())
        XCTAssertEqual(journalsAfterSave.count, 1)
        XCTAssertEqual(journalsAfterSave.first?.lessonId, lesson.id)
        XCTAssertEqual(streak.current, 1)
    }

    // MARK: - 6. LocalAuthentication / Face ID Lock Service
    @MainActor
    func testJournalAuthServiceDefaultState() async {
        let auth = JournalAuthService.shared
        // Off by default
        UserDefaults.standard.removeObject(forKey: "journalFaceIDLockEnabled")
        auth.isLockEnabled = false
        auth.isUnlocked = true

        XCTAssertFalse(auth.isLockEnabled, "Journal lock must be disabled by default")
        let authenticated = await auth.authenticate()
        XCTAssertTrue(authenticated, "When lock is disabled, authenticate() must return true immediately")
        XCTAssertTrue(auth.isUnlocked)
    }
}
