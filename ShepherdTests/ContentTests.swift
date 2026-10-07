import XCTest
@testable import Shepherd

/// The bundled Bible, the shipped lesson content, per-path access, end of path, quiz choice order,
/// onboarding path mapping and the paywall's counts. tools/content/validate_content.py is the full
/// content gate; the content checks here run the same core rules against the bundle the app loads.
@MainActor
final class ContentTests: XCTestCase {

    private var store: ContentStore { ContentStore.shared }

    override func setUp() async throws {
        await ContentStore.shared.ensureBibleLoaded()
    }

    // MARK: - Bible bundle

    func testBundledBibleIsTheWholeWEB() throws {
        let bible = try XCTUnwrap(store.bible)
        XCTAssertEqual(bible.translation, "WEB")
        XCTAssertEqual(bible.edition, "engwebp")
        XCTAssertEqual(bible.books.count, 66)
        XCTAssertEqual(bible.books.reduce(0) { $0 + $1.chapters.reduce(0) { $0 + $1.verses.count } }, 31_103)
        XCTAssertEqual(bible.books.first?.abbrev, "GEN")
        XCTAssertEqual(bible.books.last?.abbrev, "REV")

        // Faithful text: the LORD edition, curly punctuation, opening quotation marks kept.
        XCTAssertEqual(store.verse(ref: "PSA.23.1"), "The LORD is my shepherd; I shall lack nothing.")
        XCTAssertEqual(store.verse(ref: "MAT.5.14"), "“You are the light of the world. A city located on a hill can’t be hidden.")
        XCTAssertEqual(store.verse(ref: "MAT.6.9"), "Pray like this: “‘Our Father in heaven, may your name be kept holy.")
        XCTAssertEqual(store.verse(ref: "REV.22.21"), "The grace of the Lord Jesus Christ be with all the saints. Amen.")
        XCTAssertNil(store.verse(ref: "GEN.1.99"))

        // Psalm superscriptions are a chapter heading, not part of verse 1.
        let psalms = try XCTUnwrap(bible.books.first { $0.abbrev == "PSA" })
        XCTAssertEqual(psalms.chapters[22].heading, "A Psalm by David.")
        XCTAssertNil(psalms.chapters[0].heading)
    }

    func testBookNameTableMatchesTheBundle() throws {
        let bible = try XCTUnwrap(store.bible)
        for book in bible.books {
            let expected = book.abbrev == "PSA" ? "Psalm" : book.name
            XCTAssertEqual(ContentStore.bookName(book.abbrev), expected, book.abbrev)
        }
        XCTAssertEqual(ContentStore.bookNames.count, 66)
    }

    func testReferenceDisplay() {
        XCTAssertEqual(ContentStore.displayRef("1CO.13.4"), "1 Corinthians 13:4")
        XCTAssertEqual(ContentStore.displayRef("PSA.23.1"), "Psalm 23:1")
        XCTAssertEqual(ContentStore.displayRefs(["MRK.1.16", "MRK.1.17", "MRK.1.18"]), "Mark 1:16–18")
        XCTAssertEqual(
            ContentStore.displayRefs(["MAT.6.9", "MAT.6.11", "PHP.4.6", "PHP.4.7"]),
            "Matthew 6:9, 11; Philippians 4:6–7"
        )
    }

    func testBibleDecodeTime() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "web", withExtension: "json"))
        let data = try Data(contentsOf: url)
        measure {
            _ = try? ContentStore.decodeBible(from: data)
        }
    }

    func testChapterNavigationCrossesBooks() throws {
        let books = try XCTUnwrap(store.bible?.books)
        XCTAssertEqual(BibleNavigation.next(book: "GEN", chapter: 50, in: books)?.label, "Exodus 1")
        XCTAssertEqual(BibleNavigation.previous(book: "EXO", chapter: 1, in: books)?.label, "Genesis 50")
        XCTAssertNil(BibleNavigation.previous(book: "GEN", chapter: 1, in: books))
        XCTAssertNil(BibleNavigation.next(book: "REV", chapter: 22, in: books))
    }

    // MARK: - Shipped content

    func testShippedContentIsValid() throws {
        XCTAssertEqual(store.paths.map(\.id), ["beginner-30", "peace-14", "mark-30"])
        var ids = Set<String>()
        for path in store.paths {
            var authored: [Int] = []
            var displayed: [Int] = []
            for lesson in path.lessons {
                XCTAssertTrue(ids.insert(lesson.id).inserted, "duplicate lesson id \(lesson.id)")
                for ref in lesson.verseRefs {
                    XCTAssertNotNil(store.verse(ref: ref), "\(lesson.id): \(ref) does not resolve")
                }
                for q in lesson.quiz {
                    XCTAssertTrue(ids.insert(q.id).inserted, "duplicate question id \(q.id)")
                    XCTAssertTrue(q.choices.indices.contains(q.correctIndex), "\(q.id): correctIndex out of range")
                    let ref = try XCTUnwrap(q.answerRef, "\(q.id): no answerRef")
                    XCTAssertTrue(lesson.verseRefs.contains(ref), "\(q.id): proof verse \(ref) is not shown in the lesson")
                    let proof = try XCTUnwrap(store.verse(ref: ref))
                    XCTAssertTrue(
                        proof.localizedCaseInsensitiveContains(q.choices[q.correctIndex]),
                        "\(q.id): answer '\(q.choices[q.correctIndex])' is not in \(ref)"
                    )
                    XCTAssertTrue(q.explain?.contains(ContentStore.displayRef(ref)) == true, "\(q.id): explain does not cite \(ref)")
                    authored.append(q.correctIndex)
                    displayed.append(try XCTUnwrap(QuizRules.displayOrder(for: q).firstIndex(of: q.correctIndex)))
                }
            }
            if authored.count >= 4 {
                XCTAssertGreaterThan(Set(authored).count, 1, "\(path.id): every answer is choice #\(authored[0])")
                XCTAssertGreaterThan(Set(displayed).count, 1, "\(path.id): every answer is shown in the same position")
            }
        }
    }

    // MARK: - Per-path access

    private func lessons(_ n: Int, prefix: String) -> [Lesson] {
        (1...n).map {
            Lesson(id: "\(prefix).d\($0)", dayIndex: $0, title: "L\($0)", verseRefs: ["GEN.1.1"], bodyMarkdown: "", prayerPrompt: nil, quiz: [])
        }
    }

    func testFreeAndSeasonalPathsAreAlwaysOpen() {
        for access in [PathAccess.free, .seasonal] {
            let path = StudyPath(id: "p", title: "P", level: "beginner", estimatedDays: 5, access: access, lessons: lessons(5, prefix: "p"))
            for lesson in path.lessons {
                XCTAssertTrue(PathAccessPolicy.isUnlocked(lesson, in: path, isPremium: false), "\(access) day \(lesson.dayIndex)")
            }
        }
    }

    func testPremiumPathOpensItsPreviewFreeAndTheRestWithPremium() {
        let path = StudyPath(id: "p", title: "P", level: "beginner", estimatedDays: 5, access: .premium, freePreviewLessons: 3, lessons: lessons(5, prefix: "p"))
        let freeUser = path.lessons.map { PathAccessPolicy.isUnlocked($0, in: path, isPremium: false) }
        XCTAssertEqual(freeUser, [true, true, true, false, false])
        let premiumUser = path.lessons.map { PathAccessPolicy.isUnlocked($0, in: path, isPremium: true) }
        XCTAssertEqual(premiumUser, [true, true, true, true, true])
        XCTAssertEqual(PathAccessPolicy.label(for: path), "Premium · first 3 lessons free")
    }

    func testShippedPathAccess() throws {
        let beginner = try XCTUnwrap(store.path(id: "beginner-30"))
        XCTAssertEqual(beginner.access, .free)
        XCTAssertTrue(beginner.lessons.allSatisfy { PathAccessPolicy.isUnlocked($0, in: beginner, isPremium: false) })
        XCTAssertEqual(beginner.lessons.count, 30)
        XCTAssertFalse(beginner.isDraft)
        for (id, count) in [("peace-14", 14), ("mark-30", 30)] {
            let path = try XCTUnwrap(store.path(id: id))
            XCTAssertEqual(path.access, .premium, id)
            XCTAssertEqual(path.freePreviewLessons, 3, id)
            XCTAssertEqual(path.lessons.count, count, id)
            XCTAssertFalse(path.isDraft, "\(id) is complete and must not ship as a draft")
            for lesson in path.lessons {
                XCTAssertEqual(PathAccessPolicy.isUnlocked(lesson, in: path, isPremium: false), lesson.dayIndex <= 3, "\(lesson.id): only days 1-3 are a free preview")
                XCTAssertTrue(PathAccessPolicy.isUnlocked(lesson, in: path, isPremium: true), "\(lesson.id) is open to Premium")
            }
        }
    }

    // MARK: - End of path

    func testEndOfPathHasNoNextLesson() {
        let path = StudyPath(id: "p", title: "P", level: "beginner", estimatedDays: 3, lessons: lessons(3, prefix: "p"))
        XCTAssertEqual(PathProgress.nextLesson(in: path, completed: [])?.id, "p.d1")
        XCTAssertEqual(PathProgress.nextLesson(in: path, completed: ["p.d1", "p.d3"])?.id, "p.d2")
        XCTAssertFalse(PathProgress.isComplete(path, completed: ["p.d1", "p.d2"]))

        let all: Set<String> = ["p.d1", "p.d2", "p.d3"]
        XCTAssertNil(PathProgress.nextLesson(in: path, completed: all), "a finished path must not offer its last day again")
        XCTAssertTrue(PathProgress.isComplete(path, completed: all))
        XCTAssertEqual(PathProgress.completedCount(in: path, completed: all.union(["other.d1"])), 3)
    }

    func testActivePathFallsBackToTheFirstPath() {
        XCTAssertEqual(store.activePath(id: nil)?.id, "beginner-30")
        XCTAssertEqual(store.activePath(id: "mark-30")?.id, "mark-30")
        XCTAssertEqual(store.activePath(id: "no-such-path")?.id, "beginner-30")
    }

    // MARK: - Quiz choice order

    func testChoiceOrderIsAStablePermutation() throws {
        for path in store.paths {
            for q in path.lessons.flatMap(\.quiz) {
                let order = QuizRules.displayOrder(for: q)
                XCTAssertEqual(order.sorted(), Array(q.choices.indices), "\(q.id): not a permutation")
                XCTAssertEqual(QuizRules.displayOrder(for: q), order, "\(q.id): not stable")
            }
        }
        // Pinned values: the order must be the same on every launch and device, so it cannot
        // come from Swift's per-process randomised hashValue.
        let q = QuizQuestion(id: "day1-q1", prompt: "", choices: ["a", "b", "c", "d"], correctIndex: 1, explain: nil)
        XCTAssertEqual(QuizRules.displayOrder(for: q), [3, 2, 1, 0])
        let q2 = QuizQuestion(id: "peace-14.d01.q2", prompt: "", choices: ["a", "b", "c", "d"], correctIndex: 2, explain: nil)
        XCTAssertEqual(QuizRules.displayOrder(for: q2), [1, 2, 0, 3])
    }

    func testChoiceOrderDoesNotDependOnTheAnswer() {
        let a = QuizQuestion(id: "x.q1", prompt: "", choices: ["a", "b", "c", "d"], correctIndex: 0, explain: nil)
        let b = QuizQuestion(id: "x.q1", prompt: "", choices: ["a", "b", "c", "d"], correctIndex: 3, explain: nil)
        XCTAssertEqual(QuizRules.displayOrder(for: a), QuizRules.displayOrder(for: b))
    }

    func testAnsweringVerseUsesAnswerRefAndNeverAnUnrelatedVerse() {
        let verses = ["PHP.4.7": "And the peace of God, which surpasses all understanding, will guard your hearts and your thoughts in Christ Jesus."]
        let lesson = Lesson(id: "l", dayIndex: 1, title: "", verseRefs: ["PHP.4.7"], bodyMarkdown: "", prayerPrompt: nil, quiz: [])
        let withRef = QuizQuestion(id: "q", prompt: "", choices: ["x", "y"], correctIndex: 0, answerRef: "PHP.4.7", explain: nil)
        XCTAssertEqual(QuizRules.answeringVerse(for: withRef, in: lesson) { verses[$0] }?.ref, "PHP.4.7")

        let unmatched = QuizQuestion(id: "q", prompt: "", choices: ["Hearts and thoughts", "y"], correctIndex: 0, explain: nil)
        XCTAssertNil(QuizRules.answeringVerse(for: unmatched, in: lesson) { verses[$0] }, "no Genesis 1:1 fallback")

        let apostrophe = ["GEN.1.27": "In God’s image he created him"]
        let l2 = Lesson(id: "l2", dayIndex: 1, title: "", verseRefs: ["GEN.1.27"], bodyMarkdown: "", prayerPrompt: nil, quiz: [])
        let straight = QuizQuestion(id: "q", prompt: "", choices: ["God's", "y"], correctIndex: 0, explain: nil)
        XCTAssertEqual(QuizRules.answeringVerse(for: straight, in: l2) { apostrophe[$0] }?.ref, "GEN.1.27")
    }

    // MARK: - Onboarding -> suggested path (report §4.3)

    func testOnboardingGoalSuggestsAPath() {
        let expected: [(String, String, String)] = [
            ("grow_daily", "beginner", "beginner-30"), ("grow_daily", "some", "beginner-30"), ("grow_daily", "deep", "mark-30"),
            ("understand", "beginner", "beginner-30"), ("understand", "some", "mark-30"), ("understand", "deep", "mark-30"),
            ("peace", "beginner", "peace-14"), ("peace", "some", "peace-14"), ("peace", "deep", "peace-14"),
        ]
        for (goal, level, id) in expected {
            XCTAssertEqual(PathRecommender.recommendedPath(goal: goal, level: level, in: store.paths)?.id, id, "\(goal)/\(level)")
        }
        // A suggestion missing from content falls back to the free path.
        let onlyFree = store.paths.filter { $0.access == .free }
        XCTAssertEqual(PathRecommender.recommendedPath(goal: "peace", level: "some", in: onlyFree)?.id, "beginner-30")
    }

    // MARK: - Honest paywall

    func testPaywallCountsComeFromContent() {
        // The launch shape: Peace 14 and Mark 30, each with 3 free preview lessons.
        let offer = PremiumOffer(paths: store.paths)
        let premiumOnly = store.paths
            .filter { $0.access == .premium }
            .reduce(0) { $0 + max(0, $1.lessons.count - $1.freePreviewLessons) }
        XCTAssertEqual(offer.lessonCount, premiumOnly)
        XCTAssertEqual(offer.lessonCount, 38)
        XCTAssertEqual(offer.pathsSummary, "38 Premium lessons in 2 paths")
        XCTAssertEqual(offer.unlocksLine, "Premium unlocks: 38 Premium lessons in 2 paths (Peace & Prayer: 14 Days; Meet Jesus: Mark in 30 Days), streak freezes")

        for claim in ["full learning paths", "outfits", "widgets", "reminders"] {
            XCTAssertFalse(offer.unlocksLine.localizedCaseInsensitiveContains(claim), "paywall claims '\(claim)', which this build does not offer")
        }
    }

    func testPaywallCountsOnlyLessonsBeyondTheFreePreview() {
        // Launch shape: Peace 14 and Mark 30 with 3 free each -> 38 Premium lessons, not 44.
        let peace = StudyPath(id: "peace", title: "Peace", level: "beginner", estimatedDays: 14, sortOrder: 2, access: .premium, freePreviewLessons: 3, lessons: lessons(14, prefix: "peace"))
        let mark = StudyPath(id: "mark", title: "Mark", level: "some", estimatedDays: 30, sortOrder: 3, access: .premium, freePreviewLessons: 3, lessons: lessons(30, prefix: "mark"))
        let free = StudyPath(id: "free", title: "Free", level: "beginner", estimatedDays: 30, sortOrder: 1, lessons: lessons(30, prefix: "free"))
        let offer = PremiumOffer(paths: [free, peace, mark])
        XCTAssertEqual(offer.lessonCount, 38)
        XCTAssertEqual(offer.pathsSummary, "38 Premium lessons in 2 paths")
        XCTAssertEqual(offer.unlocksLine, "Premium unlocks: 38 Premium lessons in 2 paths (Peace; Mark), streak freezes")

        // A Premium path with one lesson past its preview, and one with none.
        let stub = StudyPath(id: "stub", title: "Stub", level: "beginner", estimatedDays: 3, access: .premium, freePreviewLessons: 3, lessons: lessons(3, prefix: "stub"))
        let four = StudyPath(id: "four", title: "Four", level: "beginner", estimatedDays: 4, access: .premium, freePreviewLessons: 3, lessons: lessons(4, prefix: "four"))
        XCTAssertEqual(PremiumOffer(paths: [stub, four]).pathsSummary, "1 Premium lesson in 1 path")
        XCTAssertEqual(PremiumOffer(paths: [stub, four]).pathTitles, ["Four"])
    }

    // MARK: - Lesson display typography

    func testCurlyQuotesAtDisplayTime() {
        XCTAssertEqual(LessonText.curlyQuotes(#"God speaks: "Let there be light." It is God's work."#),
                       "God speaks: \u{201C}Let there be light.\u{201D} It is God\u{2019}s work.")
        XCTAssertEqual(LessonText.curlyQuotes(#""Who?" (He said "go.")"#),
                       "\u{201C}Who?\u{201D} (He said \u{201C}go.\u{201D})")
        // Markdown emphasis is looked through; a fill-in blank's underscores are not.
        XCTAssertEqual(LessonText.curlyQuotes(#"**"Word"** and *"aid"*"#), "**\u{201C}Word\u{201D}** and *\u{201C}aid\u{201D}*")
        XCTAssertEqual(LessonText.curlyQuotes(#""saved through ___""#), "\u{201C}saved through ___\u{201D}")
        // WEB's own curly punctuation inside a straight quotation stays as it is.
        XCTAssertEqual(LessonText.curlyQuotes(#""Don’t be afraid.""#), "\u{201C}Don’t be afraid.\u{201D}")
        XCTAssertEqual(Lesson(id: "x", dayIndex: 1, title: "Made in God's image", verseRefs: [], bodyMarkdown: "", prayerPrompt: nil, quiz: []).displayTitle,
                       "Made in God\u{2019}s image")
    }

    /// Every lesson string the app shows comes out with no straight quotes, balanced double
    /// quotes, and nothing changed but the quote marks.
    func testEveryShownLessonStringGetsBalancedCurlyQuotes() {
        var checked = 0
        for path in store.paths {
            for lesson in path.lessons {
                var texts = [lesson.title, lesson.bodyMarkdown, lesson.prayerPrompt ?? ""]
                for q in lesson.quiz {
                    texts += [q.prompt, q.explain ?? ""] + q.choices
                }
                for text in texts where !text.isEmpty {
                    let shown = LessonText.curlyQuotes(text)
                    XCTAssertFalse(shown.contains("\"") || shown.contains("'"), "\(lesson.id): \(shown)")
                    XCTAssertEqual(shown.filter { $0 == "\u{201C}" }.count, shown.filter { $0 == "\u{201D}" }.count, "\(lesson.id): \(shown)")
                    XCTAssertEqual(QuizRules.normalizedQuotes(shown), QuizRules.normalizedQuotes(text), lesson.id)
                    checked += 1
                }
            }
        }
        XCTAssertGreaterThan(checked, 1_000)
    }

    /// The lesson screen draws one "Reflection" heading: the body's own **Reflection:** label
    /// becomes that heading and is not shown again inside the text.
    func testLessonBodyHasOneReflectionAndNoInlineLabel() {
        XCTAssertEqual(LessonText.blocks(fromBody: "Intro \"x\".\n\n**Reflection:** Where are you?\n\n*Study aid: note.*"),
                       [.paragraph("Intro \"x\"."), .reflection("Where are you?"), .paragraph("*Study aid: note.*")])
        for path in store.paths {
            for lesson in path.lessons {
                let blocks = LessonText.blocks(fromBody: lesson.bodyMarkdown)
                let reflections = blocks.compactMap { if case .reflection(let q) = $0 { return q } else { return nil } }
                XCTAssertEqual(reflections.count, 1, lesson.id)
                XCTAssertFalse(reflections.first?.isEmpty ?? true, lesson.id)
                for block in blocks {
                    let text: String
                    switch block {
                    case .paragraph(let p): text = p
                    case .reflection(let q): text = q
                    }
                    XCTAssertFalse(text.contains("Reflection:"), "\(lesson.id) shows the Reflection label twice")
                }
            }
        }
    }
}
