import XCTest
import SwiftData
@testable import Shepherd

final class BibleUserDataTests: XCTestCase {

    // MARK: - 1. Additive SwiftData Migration Test
    @MainActor
    func testAdditiveMigrationFromV1Store() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let storeURL = tempDir.appendingPathComponent("shepherd_migration_test.store")

        // Step 1: Create store using only V1 schema models
        let v1Schema = Schema([
            UserProfile.self,
            Companion.self,
            StreakState.self,
            LessonProgress.self,
            EntitlementState.self
        ])
        let v1Config = ModelConfiguration(schema: v1Schema, url: storeURL)
        do {
            let v1Container = try ModelContainer(for: v1Schema, configurations: v1Config)
            let v1Context = ModelContext(v1Container)

            let profile = UserProfile(displayName: "TestUser", goal: "peace", experienceLevel: "some", dailyMinutes: 10)
            let companion = Companion(name: "Pip", stage: 2, xp: 75)
            let streak = StreakState(current: 5, best: 8)
            let progress = LessonProgress(lessonId: "day1", quizScore: 2)

            v1Context.insert(profile)
            v1Context.insert(companion)
            v1Context.insert(streak)
            v1Context.insert(progress)
            try v1Context.save()
        }

        // Step 2: Open the existing store using the new additive schema including Bible models
        let v2Schema = Schema([
            UserProfile.self,
            Companion.self,
            StreakState.self,
            LessonProgress.self,
            EntitlementState.self,
            BibleHighlight.self,
            BibleBookmark.self,
            BibleNote.self
        ])
        let v2Config = ModelConfiguration(schema: v2Schema, url: storeURL)
        let v2Container = try ModelContainer(for: v2Schema, configurations: v2Config)
        let v2Context = ModelContext(v2Container)

        // Step 3: Verify existing V1 data was preserved seamlessly
        let fetchedProfiles = try v2Context.fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(fetchedProfiles.count, 1)
        XCTAssertEqual(fetchedProfiles.first?.displayName, "TestUser")
        XCTAssertEqual(fetchedProfiles.first?.goal, "peace")

        let fetchedCompanions = try v2Context.fetch(FetchDescriptor<Companion>())
        XCTAssertEqual(fetchedCompanions.count, 1)
        XCTAssertEqual(fetchedCompanions.first?.name, "Pip")
        XCTAssertEqual(fetchedCompanions.first?.xp, 75)

        let fetchedStreaks = try v2Context.fetch(FetchDescriptor<StreakState>())
        XCTAssertEqual(fetchedStreaks.count, 1)
        XCTAssertEqual(fetchedStreaks.first?.current, 5)
        XCTAssertEqual(fetchedStreaks.first?.best, 8)

        let fetchedProgress = try v2Context.fetch(FetchDescriptor<LessonProgress>())
        XCTAssertEqual(fetchedProgress.count, 1)
        XCTAssertEqual(fetchedProgress.first?.lessonId, "day1")

        // Step 4: Verify new Bible models can be inserted and fetched in the migrated store
        let highlight = BibleHighlight(book: "GEN", chapter: 1, startVerse: 1, endVerse: 3, colorName: "yellow", verseText: "In the beginning...")
        let bookmark = BibleBookmark(book: "PSA", chapter: 23, startVerse: 1, endVerse: 1, verseText: "The Lord is my shepherd...")
        let note = BibleNote(book: "JHN", chapter: 3, startVerse: 16, endVerse: 16, noteText: "Core gospel verse", verseText: "For God so loved the world...")

        v2Context.insert(highlight)
        v2Context.insert(bookmark)
        v2Context.insert(note)
        try v2Context.save()

        let fetchedHighlights = try v2Context.fetch(FetchDescriptor<BibleHighlight>())
        XCTAssertEqual(fetchedHighlights.count, 1)
        XCTAssertEqual(fetchedHighlights.first?.book, "GEN")
        XCTAssertEqual(fetchedHighlights.first?.startVerse, 1)
        XCTAssertEqual(fetchedHighlights.first?.endVerse, 3)

        let fetchedBookmarks = try v2Context.fetch(FetchDescriptor<BibleBookmark>())
        XCTAssertEqual(fetchedBookmarks.count, 1)
        XCTAssertEqual(fetchedBookmarks.first?.book, "PSA")

        let fetchedNotes = try v2Context.fetch(FetchDescriptor<BibleNote>())
        XCTAssertEqual(fetchedNotes.count, 1)
        XCTAssertEqual(fetchedNotes.first?.noteText, "Core gospel verse")
    }

    // MARK: - 2. Formatted Scripture Copy / Share Output
    func testBibleFormatterAttributionAndReference() {
        // Single verse format
        let single = BibleFormatter.formattedText(
            bookName: "Genesis",
            chapter: 1,
            startVerse: 1,
            endVerse: 1,
            verseTexts: ["In the beginning, God created the heavens and the earth."]
        )

        XCTAssertTrue(single.contains("In the beginning, God created the heavens and the earth."))
        XCTAssertTrue(single.contains("Genesis 1:1"))
        XCTAssertTrue(single.contains("World English Bible"))

        // Multi-verse range format
        let range = BibleFormatter.formattedText(
            bookName: "Genesis",
            chapter: 1,
            startVerse: 1,
            endVerse: 3,
            verseTexts: [
                "In the beginning, God created the heavens and the earth.",
                "The earth was formless and empty.",
                "God said, “Let there be light,” and there was light."
            ]
        )

        XCTAssertTrue(range.contains("Genesis 1:1–3"))
        XCTAssertTrue(range.contains("World English Bible"))
        XCTAssertTrue(range.contains("Let there be light"))
    }

    // MARK: - 3. Highlight Overlap and Range Logic
    func testHighlightOverlapAndContains() {
        let h = BibleHighlight(book: "GEN", chapter: 1, startVerse: 2, endVerse: 4, colorName: "blue")

        XCTAssertFalse(h.contains(verse: 1))
        XCTAssertTrue(h.contains(verse: 2))
        XCTAssertTrue(h.contains(verse: 3))
        XCTAssertTrue(h.contains(verse: 4))
        XCTAssertFalse(h.contains(verse: 5))

        // Overlap checks
        XCTAssertTrue(h.overlaps(start: 1, end: 2))
        XCTAssertTrue(h.overlaps(start: 4, end: 6))
        XCTAssertTrue(h.overlaps(start: 3, end: 3))
        XCTAssertFalse(h.overlaps(start: 5, end: 8))
        XCTAssertFalse(h.overlaps(start: 1, end: 1))

        // Normalization when start > end
        let reversed = BibleHighlight(book: "GEN", chapter: 1, startVerse: 5, endVerse: 2, colorName: "purple")
        XCTAssertEqual(reversed.startVerse, 2)
        XCTAssertEqual(reversed.endVerse, 5)
    }

    // MARK: - 4. Bookmark and Note Range Logic
    func testBookmarkAndNoteRangeLogic() {
        let b = BibleBookmark(book: "PSA", chapter: 23, startVerse: 4, endVerse: 1)
        XCTAssertEqual(b.startVerse, 1)
        XCTAssertEqual(b.endVerse, 4)
        XCTAssertTrue(b.contains(verse: 3))

        let n = BibleNote(book: "ROM", chapter: 8, startVerse: 28, endVerse: nil, noteText: "God works all things together for good")
        XCTAssertEqual(n.startVerse, 28)
        XCTAssertEqual(n.endVerse, 28)
        XCTAssertTrue(n.contains(verse: 28))
        XCTAssertFalse(n.contains(verse: 29))
    }

    // MARK: - 5. Highlight Colors Contrast Check
    func testHighlightColorsContrastCheck() {
        // WCAG AA contrast calculation verification
        func luminance(r: Double, g: Double, b: Double) -> Double {
            func channel(_ c: Double) -> Double {
                c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
        }

        func contrastRatio(l1: Double, l2: Double) -> Double {
            let maxL = max(l1, l2)
            let minL = min(l1, l2)
            return (maxL + 0.05) / (minL + 0.05)
        }

        // Flock TextPrimary:
        // Light: #18163A -> (24/255, 22/255, 58/255)
        let textLightL = luminance(r: 24/255.0, g: 22/255.0, b: 58/255.0)
        // Dark: #F6F5FF -> (246/255, 245/255, 255/255)
        let textDarkL = luminance(r: 246/255.0, g: 245/255.0, b: 255/255.0)

        // Shipped colors:
        let highlights: [String: (light: (Double, Double, Double), dark: (Double, Double, Double))] = [
            "Yellow": (light: (1.0, 0.953, 0.722), dark: (0.231, 0.200, 0.102)),
            "Blue": (light: (0.886, 0.933, 0.992), dark: (0.106, 0.184, 0.267)),
            "Purple": (light: (0.945, 0.902, 0.988), dark: (0.192, 0.122, 0.259)),
            "Rose": (light: (0.988, 0.894, 0.925), dark: (0.239, 0.114, 0.169)),
            "Amber": (light: (1.000, 0.910, 0.820), dark: (0.243, 0.165, 0.098))
        ]

        for (name, values) in highlights {
            let bgLightL = luminance(r: values.light.0, g: values.light.1, b: values.light.2)
            let bgDarkL = luminance(r: values.dark.0, g: values.dark.1, b: values.dark.2)

            let ratioLight = contrastRatio(l1: textLightL, l2: bgLightL)
            let ratioDark = contrastRatio(l1: textDarkL, l2: bgDarkL)

            XCTAssertGreaterThanOrEqual(ratioLight, 4.5, "\(name) Light contrast must meet WCAG AA (>= 4.5:1), got \(ratioLight)")
            XCTAssertGreaterThanOrEqual(ratioDark, 4.5, "\(name) Dark contrast must meet WCAG AA (>= 4.5:1), got \(ratioDark)")
        }
    }
}
