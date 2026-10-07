import XCTest
import UIKit
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
        let genesis1 = [
            BibleVerse(number: 1, text: "In the beginning, God created the heavens and the earth."),
            BibleVerse(number: 2, text: "The earth was formless and empty."),
            BibleVerse(number: 3, text: "God said, “Let there be light,” and there was light."),
        ]

        let single = BibleFormatter.formattedText(bookName: "Genesis", chapter: 1, verses: [genesis1[0]])
        XCTAssertTrue(single.contains("In the beginning, God created the heavens and the earth."))
        XCTAssertTrue(single.contains("Genesis 1:1\n"))
        XCTAssertTrue(single.contains("World English Bible"))

        let range = BibleFormatter.formattedText(bookName: "Genesis", chapter: 1, verses: genesis1)
        XCTAssertTrue(range.contains("Genesis 1:1–3"))
        XCTAssertTrue(range.contains("World English Bible"))
        XCTAssertTrue(range.contains("Let there be light"))
    }

    // MARK: - 3. Review B1: a selection that skips verses
    /// Tapping verse 1 then verse 3 selects 1–3: verse 2 is drawn as selected and is part of every
    /// action, so the copied text labelled "Genesis 1:1–3" really contains verse 2.
    @MainActor
    func testTappingVersesOneAndThreeSelectsTheVerseBetween() async throws {
        var selection = VerseSelection()
        selection.tap(1)
        selection.tap(3)
        XCTAssertEqual(selection.verses, [1, 2, 3])
        XCTAssertTrue(selection.contains(2), "verse 2 must be drawn as selected")

        await ContentStore.shared.ensureBibleLoaded()
        let chapter = try XCTUnwrap(ContentStore.shared.bible?.books.first?.chapters.first)
        let verses = chapter.verses.filter { selection.contains($0.number) }
        let copied = BibleFormatter.formattedText(bookName: "Genesis", chapter: 1, verses: verses)
        let verse2 = try XCTUnwrap(chapter.verses.first { $0.number == 2 }?.text)
        XCTAssertTrue(copied.contains(verse2), "copied text must contain verse 2:\n\(copied)")
        XCTAssertTrue(copied.contains("Genesis 1:1–3"))
    }

    func testVerseSelectionTapRules() {
        var selection = VerseSelection()
        selection.tap(5)
        XCTAssertEqual(selection.range, 5...5)
        selection.tap(2)
        XCTAssertEqual(selection.range, 2...5, "tapping before the run extends it")
        selection.tap(2)
        XCTAssertEqual(selection.range, 3...5, "tapping the first verse deselects it")
        selection.tap(4)
        XCTAssertEqual(selection.range, 3...3, "tapping inside deselects that verse and the ones after it")
        selection.tap(3)
        XCTAssertNil(selection.range)
        XCTAssertTrue(selection.isEmpty)
    }

    /// Whatever verses reach the formatter, the reference names exactly those verses.
    func testReferenceForVersesThatSkipNamesEachRun() {
        let skipping = BibleFormatter.referenceString(bookName: "Genesis", chapter: 1, verses: [1, 3])
        XCTAssertFalse(skipping.contains("1:1–3"), skipping)
        XCTAssertEqual(skipping, "Genesis 1:1, 3")
        XCTAssertEqual(BibleFormatter.referenceString(bookName: "Genesis", chapter: 1, verses: [5, 1, 2, 3]), "Genesis 1:1–3, 5")
        XCTAssertEqual(BibleFormatter.referenceString(bookName: "Psalms", chapter: 119, verses: [150]), "Psalms 119:150")

        let text = BibleFormatter.formattedText(bookName: "Genesis", chapter: 1, verses: [
            BibleVerse(number: 1, text: "In the beginning, God created the heavens and the earth."),
            BibleVerse(number: 3, text: "God said, “Let there be light,” and there was light."),
        ])
        XCTAssertFalse(text.contains("1:1–3"), text)
        XCTAssertTrue(text.contains("Genesis 1:1, 3"))
    }

    // MARK: - 4. Review B2: editing part of a saved range keeps the rest
    func testRecolouringOneVerseInsideAHighlightKeepsTheRest() {
        let yellow = [VerseSpan(1...10, "yellow")]
        let result = BibleRangeEditor.applying(VerseSpan(5...5, "blue"), to: yellow)
        XCTAssertEqual(result, [VerseSpan(1...4, "yellow"), VerseSpan(5...5, "blue"), VerseSpan(6...10, "yellow")])

        // The review's app repro: 1–3 yellow, recolour verse 2 rose.
        XCTAssertEqual(
            BibleRangeEditor.applying(VerseSpan(2...2, "rose"), to: [VerseSpan(1...3, "yellow")]),
            [VerseSpan(1...1, "yellow"), VerseSpan(2...2, "rose"), VerseSpan(3...3, "yellow")]
        )
    }

    func testRemovingPartOfARangeKeepsTheVersesOutsideIt() {
        XCTAssertEqual(
            BibleRangeEditor.removing(2...2, from: [VerseSpan(1...3, "yellow")]),
            [VerseSpan(1...1, "yellow"), VerseSpan(3...3, "yellow")]
        )
        XCTAssertEqual(BibleRangeEditor.removing(1...5, from: [VerseSpan(3...8, "blue")]), [VerseSpan(6...8, "blue")])
        XCTAssertEqual(BibleRangeEditor.removing(1...9, from: [VerseSpan(3...8, "blue")]), [])
        XCTAssertEqual(
            BibleRangeEditor.removing(4...4, from: [VerseSpan(1...2, "a"), VerseSpan(6...7, "b")]),
            [VerseSpan(1...2, "a"), VerseSpan(6...7, "b")],
            "highlights that do not overlap are untouched"
        )
    }

    // MARK: - 5. Model range logic
    func testHighlightOverlapAndContains() {
        let h = BibleHighlight(book: "GEN", chapter: 1, startVerse: 2, endVerse: 4, colorName: "blue")

        XCTAssertFalse(h.contains(verse: 1))
        XCTAssertTrue(h.contains(verse: 2))
        XCTAssertTrue(h.contains(verse: 4))
        XCTAssertFalse(h.contains(verse: 5))

        XCTAssertTrue(h.overlaps(start: 1, end: 2))
        XCTAssertTrue(h.overlaps(start: 4, end: 6))
        XCTAssertFalse(h.overlaps(start: 5, end: 8))
        XCTAssertFalse(h.overlaps(start: 1, end: 1))

        let reversed = BibleHighlight(book: "GEN", chapter: 1, startVerse: 5, endVerse: 2, colorName: "purple")
        XCTAssertEqual(reversed.startVerse, 2)
        XCTAssertEqual(reversed.endVerse, 5)

        let b = BibleBookmark(book: "PSA", chapter: 23, startVerse: 4, endVerse: 1)
        XCTAssertEqual(b.startVerse...b.endVerse, 1...4)
        let n = BibleNote(book: "ROM", chapter: 8, startVerse: 28, endVerse: nil, noteText: "God works all things together for good")
        XCTAssertEqual(n.startVerse...n.endVerse, 28...28)
    }

    // MARK: - 6. Review N1: contrast of the shipped colour sets
    /// Reads the colour sets the app ships (not copies of their values) in light and dark, and checks
    /// text on every highlight at 4.5:1 and each swatch dot on its own fill at 3:1.
    func testShippedHighlightColoursMeetContrast() throws {
        let bundle = Bundle(for: BibleHighlight.self)
        func luminance(_ color: UIColor) -> Double {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            XCTAssertTrue(color.getRed(&r, green: &g, blue: &b, alpha: &a))
            func channel(_ c: CGFloat) -> Double {
                let c = Double(c)
                return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
        }
        func ratio(_ a: UIColor, _ b: UIColor) -> Double {
            let (x, y) = (luminance(a), luminance(b))
            return (max(x, y) + 0.05) / (min(x, y) + 0.05)
        }

        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            func shipped(_ name: String) throws -> UIColor {
                let color = try XCTUnwrap(UIColor(named: name, in: bundle, compatibleWith: traits), "no colour set \(name)")
                return color.resolvedColor(with: traits)
            }
            for highlight in BibleHighlightColor.allCases {
                let fill = try shipped(highlight.colorName)
                for text in ["TextPrimary", "TextSecondary", "AccentColor"] {
                    let r = ratio(try shipped(text), fill)
                    XCTAssertGreaterThanOrEqual(r, 4.5, "\(text) on \(highlight.colorName) (\(style == .dark ? "dark" : "light")): \(r)")
                }
                let dot = ratio(try shipped(highlight.colorName + "Swatch"), fill)
                XCTAssertGreaterThanOrEqual(dot, 3.0, "\(highlight.colorName)Swatch dot (\(style == .dark ? "dark" : "light")): \(dot)")
            }
        }
    }
}
