import XCTest
import SwiftData
import SwiftUI
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
    func testPrayerFiltering() {
        let open1 = PrayerRequest(text: "Open prayer 1")
        let answered = PrayerRequest(text: "Answered prayer 1", isAnswered: true, answeredDate: .now)
        let open2 = PrayerRequest(text: "Open prayer 2")
        let prayers = [open1, answered, open2]

        XCTAssertEqual(PrayerFilter.all.apply(to: prayers).map(\.text), ["Open prayer 1", "Answered prayer 1", "Open prayer 2"])
        XCTAssertEqual(PrayerFilter.open.apply(to: prayers).map(\.text), ["Open prayer 1", "Open prayer 2"])
        XCTAssertEqual(PrayerFilter.answered.apply(to: prayers).map(\.text), ["Answered prayer 1"])

        // Marking a prayer answered moves it between the filters
        open2.markAnswered()
        XCTAssertEqual(PrayerFilter.open.apply(to: prayers).map(\.text), ["Open prayer 1"])
        XCTAssertEqual(PrayerFilter.answered.apply(to: prayers).map(\.text), ["Answered prayer 1", "Open prayer 2"])
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

    // MARK: - 5. Reflection saved after a lesson
    @MainActor
    func testReflectionEntryLinksLessonAndSkipsBlankText() throws {
        ContentStore.shared.loadIfNeeded()
        let lesson = try XCTUnwrap(ContentStore.shared.paths.first?.lessons.first)

        XCTAssertNil(JournalEntry.reflection(on: lesson, text: ""), "an empty reflection must save nothing")
        XCTAssertNil(JournalEntry.reflection(on: lesson, text: "  \n "), "a blank reflection must save nothing")

        let entry = try XCTUnwrap(JournalEntry.reflection(on: lesson, text: "  Light out of darkness.\n"))
        XCTAssertEqual(entry.text, "Light out of darkness.")
        XCTAssertEqual(entry.lessonId, lesson.id)
        XCTAssertEqual(entry.lessonTitle, lesson.title)
        XCTAssertEqual(entry.prompt, lesson.prayerPrompt)
    }

    // MARK: - 6. Journal by path
    @MainActor
    func testReflectionsGroupByPath() throws {
        ContentStore.shared.loadIfNeeded()
        let paths = ContentStore.shared.paths
        XCTAssertGreaterThanOrEqual(paths.count, 2)
        let first = paths[0], second = paths[1]

        // Newest first, as the Journal lists them
        let fromSecond = JournalEntry(lessonId: second.lessons[0].id, text: "second path")
        let own = JournalEntry(lessonTitle: "Psalm 23", text: "my own")
        let fromFirstB = JournalEntry(lessonId: first.lessons[1].id, text: "first path, day 2")
        let fromFirstA = JournalEntry(lessonId: first.lessons[0].id, text: "first path, day 1")
        let unknown = JournalEntry(lessonId: "no-such-lesson", text: "retired lesson")

        let sections = JournalGrouping.byPath([fromSecond, own, fromFirstB, fromFirstA, unknown], paths: paths)
        XCTAssertEqual(sections.map(\.title), [first.title, second.title, "Your own reflections"])
        XCTAssertEqual(sections[0].entries.map(\.text), ["first path, day 2", "first path, day 1"])
        XCTAssertEqual(sections[1].entries.map(\.text), ["second path"])
        XCTAssertEqual(sections[2].entries.map(\.text), ["my own", "retired lesson"])
    }

    // MARK: - 7. LocalAuthentication / Face ID Lock Service
    private let lockKey = "journalFaceIDLockEnabled"

    @MainActor
    func testJournalAuthServiceDefaultState() async {
        let saved = UserDefaults.standard.object(forKey: lockKey)
        defer { UserDefaults.standard.set(saved, forKey: lockKey) }
        UserDefaults.standard.removeObject(forKey: lockKey)

        let auth = JournalAuthService()
        XCTAssertFalse(auth.isLockEnabled, "Journal lock must be disabled by default")
        XCTAssertTrue(auth.isUnlocked)
        let authenticated = await auth.authenticate()
        XCTAssertTrue(authenticated, "When lock is disabled, authenticate() must return true immediately")
        XCTAssertTrue(auth.isUnlocked)
    }

    @MainActor
    func testJournalRelocksWhenLeftOrBackgrounded() {
        let saved = UserDefaults.standard.object(forKey: lockKey)
        defer { UserDefaults.standard.set(saved, forKey: lockKey) }

        let auth = JournalAuthService()
        auth.isLockEnabled = true

        auth.isUnlocked = true
        auth.journalDidDisappear()
        XCTAssertFalse(auth.isUnlocked, "leaving the journal must lock it again")

        auth.isUnlocked = true
        auth.scenePhaseChanged(to: .inactive)
        XCTAssertTrue(auth.isUnlocked, "inactive (the Face ID prompt itself) must not lock")
        auth.scenePhaseChanged(to: .background)
        XCTAssertFalse(auth.isUnlocked, "backgrounding the app must lock the journal")

        // With the lock off there is nothing to lock
        auth.isLockEnabled = false
        auth.isUnlocked = true
        auth.journalDidDisappear()
        auth.scenePhaseChanged(to: .background)
        XCTAssertTrue(auth.isUnlocked)
    }
}
