import XCTest

final class RealFlowUITests: XCTestCase {

    private var modeOverride: String? = nil

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func saveScreenshot(_ baseName: String) {
        let shot = XCUIScreen.main.screenshot()
        let shotDir = ProcessInfo.processInfo.environment["SHOT_DIR"] ?? NSTemporaryDirectory()
        let mode = modeOverride ?? ProcessInfo.processInfo.environment["SHOT_MODE"] ?? "Light"
        let fileManager = FileManager.default
        try? fileManager.createDirectory(atPath: shotDir, withIntermediateDirectories: true)
        let filename: String
        if baseName.hasSuffix("_Light") || baseName.hasSuffix("_Dark") {
            filename = "\(baseName).png"
        } else {
            filename = "\(baseName)_\(mode).png"
        }
        let url = URL(fileURLWithPath: shotDir).appendingPathComponent(filename)
        try? shot.pngRepresentation.write(to: url)
    }

    @MainActor
    private func passOnboardingIfNeeded(_ app: XCUIApplication, goal: String = "peace", level: String = "Some experience", reminderShot: String? = nil) {
        if app.staticTexts["Welcome to Pasture"].waitForExistence(timeout: 3.0) {
            app.buttons["Continue"].tap()
            _ = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", goal)).firstMatch.waitForExistence(timeout: 2.0)
            app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", goal)).firstMatch.tap()
            app.buttons["Continue"].tap()
            _ = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", level)).firstMatch.waitForExistence(timeout: 2.0)
            app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", level)).firstMatch.tap()
            app.buttons["Continue"].tap()
            _ = app.buttons["10 min"].waitForExistence(timeout: 2.0)
            app.buttons["10 min"].tap()
            app.buttons["Continue"].tap()
            let nameField = app.textFields["Lamb’s name"]
            if nameField.waitForExistence(timeout: 2.0) {
                nameField.tap()
                nameField.typeText("Pip\n")
            }
            _ = app.buttons["Continue"].waitForExistence(timeout: 2.0)
            app.buttons["Continue"].tap()
            _ = app.buttons["Not now"].waitForExistence(timeout: 2.0)
            if let reminderShot {
                // Both choices must stay reachable at large text sizes (the step scrolls).
                XCTAssertTrue(app.staticTexts["Want a gentle daily reminder?"].exists)
                XCTAssertTrue(app.buttons["Remind me"].isHittable, "Remind me is off screen")
                XCTAssertTrue(app.buttons["Not now"].isHittable, "Not now is off screen")
                Thread.sleep(forTimeInterval: 0.3)
                saveScreenshot(reminderShot)
            }
            app.buttons["Not now"].tap()
            _ = app.buttons["See my plan"].waitForExistence(timeout: 2.0)
            app.buttons["See my plan"].tap()
            // The paywall's layout shifts when StoreKit prices arrive, which can make a tap land
            // beside the button; tap again until the paywall is gone.
            let free = app.buttons["Continue with free path"]
            _ = free.waitForExistence(timeout: 4.0)
            for _ in 0..<3 where free.exists {
                Thread.sleep(forTimeInterval: 0.5)
                free.tap()
                _ = app.navigationBars["Today"].waitForExistence(timeout: 3.0)
            }
        }
    }

    @MainActor
    private func ensureTabBarExpanded(_ app: XCUIApplication) {
        if !app.tabBars.buttons["Bible"].isHittable {
            let todayBtn = app.tabBars.buttons["Today"]
            if todayBtn.exists {
                todayBtn.tap()
                Thread.sleep(forTimeInterval: 0.5)
            }
            if !app.tabBars.buttons["Bible"].isHittable {
                app.swipeDown()
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
    }

    /// Any element whose label contains `text` (rows combine their texts into one element).
    @MainActor
    private func element(_ app: XCUIApplication, containing text: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    /// Tap the choice containing `text`, check it, and continue. A match question takes
    /// "Ref=verse start|Ref=verse start" and pairs each reference with that verse.
    @MainActor
    private func answer(_ app: XCUIApplication, _ text: String) {
        if text.contains("=") {
            for pair in text.split(separator: "|") {
                let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
                pairMatch(app, ref: parts[0], verse: parts[1])
            }
        } else {
            let choice = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
            XCTAssertTrue(choice.waitForExistence(timeout: 5.0), "no choice '\(text)'")
            choice.tap()
        }
        app.buttons["Check"].tap()
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 4.0))
        app.buttons["Continue"].tap()
    }

    /// Open Today's current lesson for `day` and answer its quiz.
    @MainActor
    private func completeLesson(_ app: XCUIApplication, day: Int, answers: [String]) {
        let node = app.buttons["Day \(day), current"]
        XCTAssertTrue(node.waitForExistence(timeout: 6.0), "Day \(day) is not the current node")
        node.tap()
        XCTAssertTrue(app.navigationBars["Day \(day)"].waitForExistence(timeout: 6.0))
        app.swipeUp()
        let quizButton = app.buttons["Take the quiz"]
        XCTAssertTrue(quizButton.waitForExistence(timeout: 4.0))
        quizButton.tap()
        for text in answers {
            answer(app, text)
        }
        XCTAssertTrue(app.staticTexts["Day \(day) complete"].waitForExistence(timeout: 6.0))
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 6.0))
    }

    @MainActor
    func testPathCompleteLight() throws {
        modeOverride = "Light"
        try executePathCompleteFlow()
    }

    @MainActor
    func testPathCompleteDark() throws {
        modeOverride = "Dark"
        try executePathCompleteFlow()
    }

    /// First Steps is free and 30 lessons long. Days 1-29 are seeded as done (DEBUG launch hook
    /// in RootView), day 30 is played through the UI; finishing it must show the path-complete
    /// state, not the last day again, and lead to the catalog.
    @MainActor
    private func executePathCompleteFlow() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uitestReset", "-uitestCompleted", "beginner-30:29"]
        app.launch()
        passOnboardingIfNeeded(app, goal: "Grow a daily habit", level: "Brand new")
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 6.0))

        completeLesson(app, day: 30, answers: ["his only born Son", "saw him and was moved with compassion", "nothing"])

        XCTAssertTrue(app.staticTexts["Path complete"].waitForExistence(timeout: 6.0))
        XCTAssertFalse(app.buttons["Day 30, current"].exists, "the finished path offers its last day again")
        Thread.sleep(forTimeInterval: 0.4)
        saveScreenshot("Home_PathComplete")

        let next = app.buttons["Choose your next path"]
        XCTAssertTrue(next.exists)
        next.tap()
        XCTAssertTrue(app.navigationBars["Paths"].waitForExistence(timeout: 4.0))
        XCTAssertTrue(element(app, containing: "30 of 30 done").exists)
        Thread.sleep(forTimeInterval: 0.3)
        saveScreenshot("Path_Overview_AfterComplete")
    }

    // MARK: - Content spot renders (three lessons per launch path)

    @MainActor
    func testLessonSpotRendersLight() throws {
        modeOverride = "Light"
        try executeLessonSpotRenders()
    }

    @MainActor
    func testLessonSpotRendersDark() throws {
        modeOverride = "Dark"
        try executeLessonSpotRenders()
    }

    /// Opens three lessons of each path from the catalog (all lessons seeded as done, Premium on)
    /// and saves the top of the lesson, its body and the first quiz question.
    @MainActor
    private func executeLessonSpotRenders() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uitestCompleted", "beginner-30,peace-14,mark-30", "-uitestPremium"]
        app.launch()
        passOnboardingIfNeeded(app, goal: "Grow a daily habit", level: "Brand new")
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 6.0))

        let picks: [(path: String, shortName: String, lessons: [(day: Int, title: String)])] = [
            ("First Steps: 30 Days with God", "FirstSteps", [(10, "The father runs"), (23, "Seventy times seven"), (30, "Looking back, walking on")]),
            ("Peace & Prayer: 14 Days", "Peace", [(6, "Thirsty"), (8, "Hannah\u{2019}s prayer"), (14, "Go in peace")]),
            ("Meet Jesus: Mark in 30 Days", "Mark", [(5, "Through the roof"), (18, "Help my unbelief"), (30, "He goes before you")]),
        ]
        for pick in picks {
            app.buttons["Path Catalogue"].tap()
            XCTAssertTrue(app.navigationBars["Paths"].waitForExistence(timeout: 4.0))
            element(app, containing: pick.path).tap()
            XCTAssertTrue(app.navigationBars[pick.path].waitForExistence(timeout: 4.0))
            for lesson in pick.lessons {
                let row = element(app, containing: lesson.title)
                var tries = 0
                while !(row.exists && row.isHittable) && tries < 12 {
                    app.swipeUp()
                    tries += 1
                }
                XCTAssertTrue(row.isHittable, "no row for \(lesson.title)")
                row.tap()
                XCTAssertTrue(app.navigationBars["Day \(lesson.day)"].waitForExistence(timeout: 6.0))
                Thread.sleep(forTimeInterval: 0.8) // verse text loads with the Bible
                let base = "Content_\(pick.shortName)_D\(lesson.day)"
                saveScreenshot("\(base)_1Top")
                app.swipeUp()
                Thread.sleep(forTimeInterval: 0.4)
                saveScreenshot("\(base)_2Body")
                app.swipeUp()
                let quizButton = app.buttons["Take the quiz"]
                XCTAssertTrue(quizButton.waitForExistence(timeout: 4.0))
                quizButton.tap()
                XCTAssertTrue(app.buttons["Check"].waitForExistence(timeout: 4.0))
                Thread.sleep(forTimeInterval: 0.4)
                saveScreenshot("\(base)_3Quiz")
                app.buttons["Close Quiz"].tap()
                Thread.sleep(forTimeInterval: 0.6)
                app.navigationBars.buttons.firstMatch.tap() // back to the lesson list
                XCTAssertTrue(app.navigationBars[pick.path].waitForExistence(timeout: 4.0))
            }
            app.navigationBars.buttons.firstMatch.tap() // Paths
            app.navigationBars.buttons.firstMatch.tap() // Today
            XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 4.0))
        }
    }

    // MARK: - App Store rating prompt (the real StoreKit sheet: "Enjoying Pasture?")

    /// Day 3's second question is a match (John 1:1 and 1:14), answered correctly.
    private let day3Match = "John 1:1=In the beginning was the Word|John 1:14=The Word became flesh"

    /// Days 1-2 seeded; Day 3 played with a perfect quiz. The rating sheet appears on Today, and a
    /// cold relaunch does not ask again.
    @MainActor
    func testReviewPromptAfterPerfectDay3() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uitestReset", "-uitestCompleted", "beginner-30:2"]
        app.launch()
        passOnboardingIfNeeded(app, goal: "Grow a daily habit", level: "Brand new")
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 6.0))
        completeLesson(app, day: 3, answers: ["Word", day3Match])
        let prompt = app.staticTexts["Enjoying Pasture?"]
        XCTAssertTrue(prompt.waitForExistence(timeout: 6.0), "no rating prompt after a perfect Day 3")
        app.buttons["Not Now"].tap()

        app.terminate()
        app.launchArguments = [] // a plain cold launch, keeping today's progress
        app.launch()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 6.0))
        XCTAssertFalse(prompt.waitForExistence(timeout: 4.0), "the rating prompt appeared on launch")
    }

    /// Day 3 with one wrong answer: no rating prompt.
    @MainActor
    func testNoReviewPromptAfterAWrongAnswer() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uitestReset", "-uitestCompleted", "beginner-30:2"]
        app.launch()
        passOnboardingIfNeeded(app, goal: "Grow a daily habit", level: "Brand new")
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 6.0))
        completeLesson(app, day: 3, answers: ["Law", day3Match])
        XCTAssertFalse(app.staticTexts["Enjoying Pasture?"].waitForExistence(timeout: 5.0), "rating prompt after a wrong answer")
    }

    @MainActor
    func testRealAppFullFlowLight() throws {
        modeOverride = "Light"
        try executeRealAppFlow()
    }

    @MainActor
    func testRealAppFullFlowDark() throws {
        modeOverride = "Dark"
        try executeRealAppFlow()
    }

    @MainActor
    func testAccessibilityAX3Light() throws {
        modeOverride = "Light"
        try executeAX3Flow()
    }

    @MainActor
    func testAccessibilityAX3Dark() throws {
        modeOverride = "Dark"
        try executeAX3Flow()
    }

    // MARK: - Exercise Types Flow (Fill-in-the-blank, Order, True/False, Match)

    @MainActor
    func testExerciseTypesLight() throws {
        modeOverride = "Light"
        try executeExerciseTypesFlow()
    }

    @MainActor
    func testExerciseTypesDark() throws {
        modeOverride = "Dark"
        try executeExerciseTypesFlow()
    }

    @MainActor
    private func executeExerciseTypesFlow() throws {
        let app = XCUIApplication()
        if modeOverride == "Dark" {
            app.launchArguments += ["-appearance", "dark"]
        }
        // -uitestReset first, so the seeded progress below does not leak into later tests.
        app.launchArguments += ["-uitestReset", "-uitestCompleted", "beginner-30,peace-14,mark-30", "-uitestPremium"]
        app.launch()
        passOnboardingIfNeeded(app, goal: "Grow a daily habit", level: "Brand new")
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 6.0))

        app.buttons["Path Catalogue"].tap()
        XCTAssertTrue(app.navigationBars["Paths"].waitForExistence(timeout: 4.0))
        element(app, containing: "First Steps: 30 Days with God").tap()
        XCTAssertTrue(app.navigationBars["First Steps: 30 Days with God"].waitForExistence(timeout: 4.0))

        // 1. Fill in the blank (Day 8: The good shepherd)
        let day8Row = element(app, containing: "The good shepherd")
        var tries = 0
        while !(day8Row.exists && day8Row.isHittable) && tries < 8 {
            app.swipeUp()
            tries += 1
        }
        XCTAssertTrue(day8Row.isHittable, "Day 8 row not hittable")
        day8Row.tap()
        XCTAssertTrue(app.navigationBars["Day 8"].waitForExistence(timeout: 6.0))
        app.swipeUp()
        let quizBtn8 = app.buttons["Take the quiz"]
        XCTAssertTrue(quizBtn8.waitForExistence(timeout: 4.0))
        quizBtn8.tap()

        XCTAssertTrue(app.buttons["Check"].waitForExistence(timeout: 4.0))
        Thread.sleep(forTimeInterval: 0.3)
        saveScreenshot("Exercise_FillBlank_Unanswered")

        let shepherdChoice = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'shepherd'")).firstMatch
        XCTAssertTrue(shepherdChoice.waitForExistence(timeout: 4.0))
        shepherdChoice.tap()
        Thread.sleep(forTimeInterval: 0.2)
        saveScreenshot("Exercise_FillBlank_Selected")

        app.buttons["Check"].tap()
        XCTAssertTrue(app.staticTexts["Correct!"].waitForExistence(timeout: 4.0))
        Thread.sleep(forTimeInterval: 0.4)
        saveScreenshot("Exercise_FillBlank_Correct")

        app.buttons["Close Quiz"].tap()
        Thread.sleep(forTimeInterval: 0.4)
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["First Steps: 30 Days with God"].waitForExistence(timeout: 4.0))

        // Scroll back up to earlier days
        while !element(app, containing: "Made in God’s image").isHittable && tries > 0 {
            app.swipeDown()
            tries -= 1
        }

        // 2. Order (Day 2: Made in God's image)
        let day2Row = element(app, containing: "Made in God’s image")
        XCTAssertTrue(day2Row.waitForExistence(timeout: 4.0))
        day2Row.tap()
        XCTAssertTrue(app.navigationBars["Day 2"].waitForExistence(timeout: 6.0))
        app.swipeUp()
        let quizBtn2 = app.buttons["Take the quiz"]
        XCTAssertTrue(quizBtn2.waitForExistence(timeout: 4.0))
        quizBtn2.tap()

        // Q1 is choice (answer: God’s)
        let q1Choice = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'God’s'")).firstMatch
        XCTAssertTrue(q1Choice.waitForExistence(timeout: 4.0))
        q1Choice.tap()
        app.buttons["Check"].tap()
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 4.0))
        app.buttons["Continue"].tap()

        // Q2 is order
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'order'")).firstMatch.waitForExistence(timeout: 4.0))
        Thread.sleep(forTimeInterval: 0.3)
        saveScreenshot("Exercise_Order_Unanswered")

        let tokens = ["In God’s image", "he created him;", "male and female", "he created them."]
        for token in tokens {
            let tokenBtn = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", token)).firstMatch
            XCTAssertTrue(tokenBtn.waitForExistence(timeout: 4.0), "missing token \(token)")
            tokenBtn.tap()
            Thread.sleep(forTimeInterval: 0.1)
        }
        Thread.sleep(forTimeInterval: 0.2)
        saveScreenshot("Exercise_Order_Selected")

        app.buttons["Check"].tap()
        XCTAssertTrue(app.staticTexts["Correct!"].waitForExistence(timeout: 4.0))
        Thread.sleep(forTimeInterval: 0.4)
        saveScreenshot("Exercise_Order_Correct")

        app.buttons["Close Quiz"].tap()
        Thread.sleep(forTimeInterval: 0.4)
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["First Steps: 30 Days with God"].waitForExistence(timeout: 4.0))

        // 3. True / False (Day 4: God so loved)
        let day4Row = element(app, containing: "God so loved")
        XCTAssertTrue(day4Row.waitForExistence(timeout: 4.0))
        day4Row.tap()
        XCTAssertTrue(app.navigationBars["Day 4"].waitForExistence(timeout: 6.0))
        app.swipeUp()
        let quizBtn4 = app.buttons["Take the quiz"]
        XCTAssertTrue(quizBtn4.waitForExistence(timeout: 4.0))
        quizBtn4.tap()

        // Q1 choice (answer: World)
        let q1World = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'World'")).firstMatch
        XCTAssertTrue(q1World.waitForExistence(timeout: 4.0))
        q1World.tap()
        app.buttons["Check"].tap()
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 4.0))
        app.buttons["Continue"].tap()

        // Q2 true_false
        let trueBtn = app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] 'True'")).firstMatch
        XCTAssertTrue(trueBtn.waitForExistence(timeout: 4.0))
        Thread.sleep(forTimeInterval: 0.3)
        saveScreenshot("Exercise_TrueFalse_Unanswered")

        let falseBtn = app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] 'False'")).firstMatch
        XCTAssertTrue(falseBtn.waitForExistence(timeout: 4.0))
        falseBtn.tap()
        Thread.sleep(forTimeInterval: 0.2)
        saveScreenshot("Exercise_TrueFalse_Selected")

        app.buttons["Check"].tap()
        XCTAssertTrue(app.staticTexts["Correct!"].waitForExistence(timeout: 4.0))
        Thread.sleep(forTimeInterval: 0.4)
        saveScreenshot("Exercise_TrueFalse_Correct")

        app.buttons["Close Quiz"].tap()
        Thread.sleep(forTimeInterval: 0.4)
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["First Steps: 30 Days with God"].waitForExistence(timeout: 4.0))

        // 4. Match (Day 3: The Word became flesh): first a wrong pairing, then the right one.
        let day3Row = element(app, containing: "The Word became flesh")
        XCTAssertTrue(day3Row.waitForExistence(timeout: 4.0))
        day3Row.tap()
        XCTAssertTrue(app.navigationBars["Day 3"].waitForExistence(timeout: 6.0))
        app.swipeUp()

        // Wrong: the sheet must spell out the correct pairs.
        openMatchQuestion(app)
        Thread.sleep(forTimeInterval: 0.3)
        saveScreenshot("Exercise_Match_Unanswered")
        pairMatch(app, ref: "John 1:1", verse: "The Word became flesh")
        pairMatch(app, ref: "John 1:14", verse: "In the beginning was the Word")
        // The pairing is visible to VoiceOver before Check.
        XCTAssertTrue(matchReference(app, "John 1:1").label.hasSuffix("matched to: The Word became flesh and lived among us."),
                      matchReference(app, "John 1:1").label)
        XCTAssertTrue(matchVerse(app, "In the beginning was the Word").label.hasSuffix("matched to John 1:14"),
                      matchVerse(app, "In the beginning was the Word").label)
        Thread.sleep(forTimeInterval: 0.2)
        saveScreenshot("Exercise_Match_WrongSelected")
        app.buttons["Check"].tap()
        XCTAssertTrue(app.staticTexts["Keep going! You’re learning."].waitForExistence(timeout: 4.0))
        let answer = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Answer:'")).firstMatch
        XCTAssertTrue(answer.waitForExistence(timeout: 2.0))
        XCTAssertEqual(answer.label, "Answer:\nJohn 1:1 matches: In the beginning was the Word\nJohn 1:14 matches: The Word became flesh and lived among us.")
        Thread.sleep(forTimeInterval: 0.4)
        saveScreenshot("Exercise_Match_Wrong")
        app.buttons["Close Quiz"].tap()
        Thread.sleep(forTimeInterval: 0.4)

        // Right.
        openMatchQuestion(app)
        pairMatch(app, ref: "John 1:1", verse: "In the beginning was the Word")
        pairMatch(app, ref: "John 1:14", verse: "The Word became flesh")
        Thread.sleep(forTimeInterval: 0.2)
        saveScreenshot("Exercise_Match_Selected")
        app.buttons["Check"].tap()
        XCTAssertTrue(app.staticTexts["Correct!"].waitForExistence(timeout: 4.0))
        Thread.sleep(forTimeInterval: 0.4)
        saveScreenshot("Exercise_Match_Correct")

        app.buttons["Close Quiz"].tap()
    }

    /// From the Day 3 lesson: start the quiz, answer q1 and land on the match question.
    @MainActor
    private func openMatchQuestion(_ app: XCUIApplication) {
        let quizButton = app.buttons["Take the quiz"]
        if !quizButton.isHittable { app.swipeUp() }
        XCTAssertTrue(quizButton.waitForExistence(timeout: 4.0))
        quizButton.tap()
        let q1Word = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Word'")).firstMatch
        XCTAssertTrue(q1Word.waitForExistence(timeout: 4.0))
        q1Word.tap()
        app.buttons["Check"].tap()
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 4.0))
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'match'")).firstMatch.waitForExistence(timeout: 4.0))
    }

    @MainActor
    private func matchReference(_ app: XCUIApplication, _ ref: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Reference \(ref),")).firstMatch
    }

    @MainActor
    private func matchVerse(_ app: XCUIApplication, _ text: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Verse: \(text)")).firstMatch
    }

    @MainActor
    private func pairMatch(_ app: XCUIApplication, ref: String, verse: String) {
        let refButton = matchReference(app, ref)
        XCTAssertTrue(refButton.waitForExistence(timeout: 4.0), "no reference \(ref)")
        refButton.tap()
        let verseButton = matchVerse(app, verse)
        XCTAssertTrue(verseButton.waitForExistence(timeout: 4.0), "no verse \(verse)")
        verseButton.tap()
    }

    // MARK: - Issue #13: Bible Reader Highlights, Bookmarks, Notes, Saved Flow
    @MainActor
    func testBibleReaderHighlightsBookmarksNotesLight() throws {
        modeOverride = "Light"
        try executeBibleSavedFlow()
    }

    @MainActor
    func testBibleReaderHighlightsBookmarksNotesDark() throws {
        modeOverride = "Dark"
        try executeBibleSavedFlow()
    }

    @MainActor
    func testVerseOfTheDayFlowLight() throws {
        modeOverride = "Light"
        try executeVerseOfTheDayFlow(appearance: "light")
    }

    @MainActor
    func testVerseOfTheDayFlowDark() throws {
        modeOverride = "Dark"
        try executeVerseOfTheDayFlow(appearance: "dark")
    }

    /// The pinned verse of the day for these tests: deep in the Bible's longest chapter, so a
    /// reader that only switches chapter without scrolling to the verse fails.
    private let deepVerseArgs = ["-uitestVerseOfDay", "PSA.119.105"]

    @MainActor
    private func verseCard(_ app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Verse of the day'")).firstMatch
    }

    /// The reader shows Psalm 119 with verse 105 on screen and marked as the verse of the day.
    @MainActor
    private func assertReaderAtDeepVerse(_ app: XCUIApplication) {
        XCTAssertTrue(app.navigationBars["Psalms"].waitForExistence(timeout: 8.0), "the reader did not open Psalms")
        let verse = app.descendants(matching: .any)["verse-105"]
        XCTAssertTrue(verse.waitForExistence(timeout: 6.0), "Psalm 119:105 is not in the reader")
        let onScreen = expectation(for: NSPredicate(format: "isHittable == true"), evaluatedWith: verse)
        wait(for: [onScreen], timeout: 6.0)
        XCTAssertEqual(verse.value as? String, "Verse of the day", "Psalm 119:105 is not highlighted")
        XCTAssertTrue(verse.label.contains("Your word is a lamp to my feet"), verse.label)
    }

    @MainActor
    private func executeVerseOfTheDayFlow(appearance: String) throws {
        let app = XCUIApplication()
        app.launchArguments = ["-appearance", appearance, "-uitestCompleted", "beginner-30:1"] + deepVerseArgs
        app.launch()
        passOnboardingIfNeeded(app)
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 8.0))

        let card = verseCard(app)
        XCTAssertTrue(card.waitForExistence(timeout: 6.0), "Verse of the day card should be visible on Today tab")
        XCTAssertTrue(card.label.contains("Psalm 119:105"), card.label)
        Thread.sleep(forTimeInterval: 0.5)
        saveScreenshot("VerseOfTheDay_Card")

        card.tap()
        assertReaderAtDeepVerse(app)
        Thread.sleep(forTimeInterval: 0.6)
        saveScreenshot("VerseOfTheDay_Reader")
    }

    /// Regression: opening the verse of the day once must not take over the reader. After picking
    /// another chapter, switching tabs used to jump back to the verse and overwrite the saved place.
    @MainActor
    func testVerseOfTheDayDoesNotOverrideLaterNavigation() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitestCompleted", "beginner-30:1"] + deepVerseArgs
        app.launch()
        passOnboardingIfNeeded(app)
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 8.0))
        let card = verseCard(app)
        XCTAssertTrue(card.waitForExistence(timeout: 6.0))
        card.tap()
        assertReaderAtDeepVerse(app)

        app.buttons["Select Book and Chapter"].tap()
        let ntSegment = app.buttons["New Testament"]
        XCTAssertTrue(ntSegment.waitForExistence(timeout: 4.0))
        ntSegment.tap()
        let johnRow = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'John'")).firstMatch
        XCTAssertTrue(johnRow.waitForExistence(timeout: 4.0))
        johnRow.tap()
        let ch3 = app.buttons["Chapter 3"]
        XCTAssertTrue(ch3.waitForExistence(timeout: 4.0))
        ch3.tap()
        XCTAssertTrue(app.navigationBars["John"].waitForExistence(timeout: 4.0))
        let heading = app.staticTexts["Chapter 3"]
        XCTAssertTrue(heading.waitForExistence(timeout: 4.0))
        XCTAssertTrue(heading.isHittable, "a newly picked chapter opens at its top")

        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 4.0))
        app.tabBars.buttons["Bible"].tap()
        XCTAssertTrue(app.navigationBars["John"].waitForExistence(timeout: 4.0), "reader jumped away from John 3 after a tab switch")
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertFalse(app.navigationBars["Psalms"].exists, "reader jumped back to the verse of the day")
        XCTAssertTrue(app.staticTexts["Chapter 3"].isHittable)
    }

    /// Widget taps open the app through widgetURL: pasture://lesson must show today's lesson and
    /// pasture://verse the reader at the verse of the day.
    @MainActor
    func testWidgetDeepLinksOpenLessonAndVerse() throws {
        let app = XCUIApplication()
        app.launchArguments = deepVerseArgs
        app.launch()
        passOnboardingIfNeeded(app)
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 8.0))

        app.open(URL(string: "pasture://lesson")!)
        let lessonBar = app.navigationBars.matching(NSPredicate(format: "identifier BEGINSWITH 'Day '")).firstMatch
        XCTAssertTrue(lessonBar.waitForExistence(timeout: 6.0), "pasture://lesson did not open today's lesson")

        app.open(URL(string: "pasture://verse")!)
        assertReaderAtDeepVerse(app)
    }

    // MARK: - Widgets on the real Home Screen (#11)

    /// Adds Pasture's widget at gallery `page` (0 verse small, 1 verse medium, 2 streak small)
    /// to the Home Screen through SpringBoard's own Edit > Add Widget sheet.
    @MainActor
    private func addHomeScreenWidget(_ springboard: XCUIApplication, page: Int) {
        if !springboard.buttons["Edit"].exists {
            // An empty spot between the icon grid and the dock enters edit mode.
            springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.82)).press(forDuration: 1.5)
        }
        XCTAssertTrue(springboard.buttons["Edit"].waitForExistence(timeout: 4.0))
        springboard.buttons["Edit"].tap()
        XCTAssertTrue(springboard.buttons["Add Widget"].waitForExistence(timeout: 4.0))
        springboard.buttons["Add Widget"].tap()
        let search = springboard.searchFields["Search Widgets"]
        XCTAssertTrue(search.waitForExistence(timeout: 4.0))
        search.tap()
        search.typeText("Pasture")
        let pastureRow = springboard.cells["Pasture"].firstMatch
        XCTAssertTrue(pastureRow.waitForExistence(timeout: 6.0), "the widget gallery does not offer Pasture")
        pastureRow.tap()
        let add = springboard.buttons[" Add Widget"]
        XCTAssertTrue(add.waitForExistence(timeout: 4.0))
        for _ in 0..<page {
            springboard.swipeLeft()
            Thread.sleep(forTimeInterval: 0.8)
        }
        add.tap()
        Thread.sleep(forTimeInterval: 1.5)
    }

    /// End to end through the App Group: the app publishes Day 30 as waiting, the extension shows
    /// it on the Home Screen; finishing Day 30 in the app turns the streak widget to "Today done".
    /// SpringBoard exposes a widget only as an icon labelled "Pasture", so the widget content is
    /// checked in the screenshots (Widgets_HomeScreen_Before/After), not by assertion. Needs a
    /// fresh simulator (`simctl erase`), since added widgets stay on the Home Screen.
    @MainActor
    func testWidgetsOnHomeScreenUpdateAfterLesson() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uitestCompleted", "beginner-30:29"]
        app.launch()
        passOnboardingIfNeeded(app, goal: "Grow a daily habit", level: "Brand new")
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 8.0))

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 1.5)
        addHomeScreenWidget(springboard, page: 0)
        addHomeScreenWidget(springboard, page: 2)
        addHomeScreenWidget(springboard, page: 1)
        springboard.buttons["Done"].tap()
        XCTAssertEqual(springboard.icons.matching(NSPredicate(format: "label == 'Pasture' AND value == 'Widget'")).count, 3)
        Thread.sleep(forTimeInterval: 2.0)
        saveScreenshot("Widgets_HomeScreen_Before")

        app.activate()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 6.0))
        completeLesson(app, day: 30, answers: ["his only born Son", "saw him and was moved with compassion", "nothing"])

        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 3.0)
        saveScreenshot("Widgets_HomeScreen_After")
    }

    @MainActor
    func testBibleKeepsChapterAcrossTabs() throws {
        let app = XCUIApplication()
        app.launch()
        passOnboardingIfNeeded(app)

        XCTAssertTrue(app.tabBars.buttons["Bible"].waitForExistence(timeout: 4.0))
        app.tabBars.buttons["Bible"].tap()
        XCTAssertTrue(app.navigationBars["Genesis"].waitForExistence(timeout: 4.0))

        let pickerBtn = app.buttons["Select Book and Chapter"]
        XCTAssertTrue(pickerBtn.waitForExistence(timeout: 4.0))
        pickerBtn.tap()

        let ntSegment = app.buttons["New Testament"]
        XCTAssertTrue(ntSegment.waitForExistence(timeout: 4.0))
        ntSegment.tap()

        let johnRow = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'John'")).firstMatch
        XCTAssertTrue(johnRow.waitForExistence(timeout: 4.0))
        johnRow.tap()

        let ch1 = app.buttons["Chapter 1"]
        XCTAssertTrue(ch1.waitForExistence(timeout: 4.0))
        ch1.tap()

        XCTAssertTrue(app.navigationBars["John"].waitForExistence(timeout: 4.0))

        // Switch to Today tab
        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 4.0))

        // Switch back to Bible tab
        app.tabBars.buttons["Bible"].tap()
        XCTAssertTrue(app.navigationBars["John"].waitForExistence(timeout: 4.0))
    }

    @MainActor
    func testRecordLambHop() throws {
        let app = XCUIApplication()
        app.launch()
        passOnboardingIfNeeded(app)

        ensureTabBarExpanded(app)
        let lambTab = app.tabBars.buttons["Lamb"]
        XCTAssertTrue(lambTab.waitForExistence(timeout: 5.0))
        lambTab.tap()

        XCTAssertTrue(app.navigationBars.element(boundBy: 0).waitForExistence(timeout: 5.0))

        Thread.sleep(forTimeInterval: 1.0)
        let lamb = app.otherElements["CompanionLamb"]
        if lamb.waitForExistence(timeout: 3.0) {
            lamb.tap()
        } else {
            app.scrollViews.otherElements.firstMatch.tap()
        }
        Thread.sleep(forTimeInterval: 2.0)
    }

    @MainActor
    func testRecordCheckMorph() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uitestReset"]
        app.launch()
        passOnboardingIfNeeded(app)

        ensureTabBarExpanded(app)
        app.tabBars.buttons["Today"].tap()
        let day1Node = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Day 1'")).firstMatch
        if day1Node.waitForExistence(timeout: 4.0) {
            day1Node.tap()
        }
        app.swipeUp()
        let quizBtn = app.buttons["Take the quiz"]
        if quizBtn.waitForExistence(timeout: 3.0) {
            quizBtn.tap()
            _ = app.staticTexts["DAY 1"].waitForExistence(timeout: 4.0)
            let wrongChoice = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'religious leaders'")).firstMatch
            if wrongChoice.waitForExistence(timeout: 4.0) {
                wrongChoice.tap()
            }
            Thread.sleep(forTimeInterval: 1.0)
            app.buttons["Check"].tap()
            XCTAssertTrue(app.staticTexts["Keep going! You’re learning."].waitForExistence(timeout: 4.0))
            Thread.sleep(forTimeInterval: 2.0)
        }
    }

    @MainActor
    private func executeRealAppFlow() throws {
        let app = XCUIApplication()
        app.launch()

        // 1. Onboarding Step 0: Welcome
        XCTAssertTrue(app.staticTexts["Welcome to Pasture"].waitForExistence(timeout: 6.0))
        Thread.sleep(forTimeInterval: 0.3)
        saveScreenshot("Onboarding_Welcome")
        app.buttons["Continue"].tap()

        // 2. Onboarding Step 1: Goal
        XCTAssertTrue(app.staticTexts["What’s your goal?"].waitForExistence(timeout: 4.0))
        Thread.sleep(forTimeInterval: 0.2)
        saveScreenshot("Onboarding_Goal")
        let goalChoice = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'peace'")).firstMatch
        if goalChoice.exists {
            goalChoice.tap()
        }
        app.buttons["Continue"].tap()

        // 3. Onboarding Step 2: Experience
        XCTAssertTrue(app.staticTexts["How familiar are you with the Bible?"].waitForExistence(timeout: 4.0))
        Thread.sleep(forTimeInterval: 0.2)
        saveScreenshot("Onboarding_Experience")
        let expChoice = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Some experience'")).firstMatch
        if expChoice.exists {
            expChoice.tap()
        }
        app.buttons["Continue"].tap()

        // 4. Onboarding Step 3: Pace
        XCTAssertTrue(app.staticTexts["How much time each day?"].waitForExistence(timeout: 4.0))
        Thread.sleep(forTimeInterval: 0.2)
        saveScreenshot("Onboarding_Pace")
        let pace10 = app.buttons["10 min"]
        if pace10.exists {
            pace10.tap()
        }
        app.buttons["Continue"].tap()

        // 5. Onboarding Step 4: Name Companion
        XCTAssertTrue(app.staticTexts["Name your companion"].waitForExistence(timeout: 4.0))
        Thread.sleep(forTimeInterval: 0.2)
        saveScreenshot("Onboarding_NameLamb")
        let nameField = app.textFields["Lamb’s name"]
        if nameField.exists {
            nameField.tap()
            nameField.typeText("Pip\n")
        }
        app.buttons["Continue"].tap()

        // 6. Onboarding Step 5: optional daily reminder. "Not now" skips it without asking iOS
        // for permission (no system alert may appear here).
        XCTAssertTrue(app.staticTexts["Want a gentle daily reminder?"].waitForExistence(timeout: 4.0))
        XCTAssertTrue(app.buttons["Remind me"].exists)
        Thread.sleep(forTimeInterval: 0.3)
        saveScreenshot("Onboarding_Reminder")
        app.buttons["Not now"].tap()
        XCTAssertFalse(XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.firstMatch.waitForExistence(timeout: 1.0),
                       "skipping the reminder asked for notification permission")

        // 7. Onboarding Step 6: Building Plan
        XCTAssertTrue(app.staticTexts["Preparing your path…"].waitForExistence(timeout: 4.0))
        // goal 'peace' -> Peace & Prayer, and the screen says honestly that it is Premium
        XCTAssertTrue(element(app, containing: "Peace & Prayer: 14 Days").exists)
        XCTAssertTrue(element(app, containing: "Premium · first 3 lessons free").exists)
        Thread.sleep(forTimeInterval: 0.3)
        saveScreenshot("Onboarding_BuildingPlan")
        app.buttons["See my plan"].tap()

        // 7. Paywall
        XCTAssertTrue(app.staticTexts["Start your 7-day free trial"].waitForExistence(timeout: 6.0))
        XCTAssertTrue(element(app, containing: "38 Premium lessons in 2 paths").exists)
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'outfits' OR label CONTAINS[c] 'widgets' OR label CONTAINS[c] 'full learning paths'")).firstMatch.exists)
        Thread.sleep(forTimeInterval: 0.3)
        saveScreenshot("Paywall_Trial")
        app.buttons["Continue with free path"].tap()

        // 8. Today Path (Empty / First Day)
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 6.0))
        Thread.sleep(forTimeInterval: 0.4)
        saveScreenshot("Home_DailyPath")

        // 9. Scroll Home to show accessory inline & scrolled state
        app.swipeUp()
        Thread.sleep(forTimeInterval: 0.3)
        saveScreenshot("Home_Scrolled")
        app.swipeDown()
        Thread.sleep(forTimeInterval: 0.3)

        // 10. Path Catalogue & Lessons List
        let mapButton = app.buttons["Path Catalogue"]
        if mapButton.waitForExistence(timeout: 3.0) {
            mapButton.tap()
            XCTAssertTrue(app.navigationBars["Paths"].waitForExistence(timeout: 4.0))
            for title in ["First Steps: 30 Days with God", "Peace & Prayer: 14 Days", "Meet Jesus: Mark in 30 Days"] {
                XCTAssertTrue(element(app, containing: title).exists, title)
            }
            XCTAssertFalse(app.staticTexts["More paths are coming"].exists)
            Thread.sleep(forTimeInterval: 0.3)
            saveScreenshot("Path_Overview")

            // Tap into the path lessons list
            let pathRow = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Days'")).firstMatch
            if pathRow.exists {
                pathRow.tap()
                Thread.sleep(forTimeInterval: 0.3)
                saveScreenshot("Path_Lessons")
                // Pop back to Paths
                app.navigationBars.buttons.element(boundBy: 0).tap()
            }
            // Pop back to Today
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }

        // 11. Open Day 1 Lesson
        let day1Node = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Day 1'")).firstMatch
        XCTAssertTrue(day1Node.waitForExistence(timeout: 4.0))
        day1Node.tap()

        XCTAssertTrue(app.navigationBars["Day 1"].waitForExistence(timeout: 6.0))
        // One "Reflection" heading; the body's own **Reflection:** label is not shown again.
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == 'Reflection'")).count, 1)
        XCTAssertFalse(element(app, containing: "Reflection:").exists, "the Reflection label shows twice")
        // Lesson copy is shown with typographic quotes (the JSON keeps straight ones).
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS '\\\"'")).firstMatch.exists, "a straight quote is on screen")
        Thread.sleep(forTimeInterval: 0.4)
        saveScreenshot("Lesson_Reading")

        // Scroll down to "Take the quiz" (past the body and its Reflection heading)
        app.swipeUp()
        Thread.sleep(forTimeInterval: 0.4)
        saveScreenshot("Lesson_Body")
        let quizButton = app.buttons["Take the quiz"]
        XCTAssertTrue(quizButton.waitForExistence(timeout: 4.0))
        quizButton.tap()

        // 12. Quiz Question 1 - Unanswered
        XCTAssertTrue(app.staticTexts["DAY 1"].waitForExistence(timeout: 6.0))
        Thread.sleep(forTimeInterval: 0.3)
        saveScreenshot("Quiz_Unanswered")

        // Select Choice ("Only religious leaders" - wrong)
        let wrongChoice = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'religious leaders'")).firstMatch
        XCTAssertTrue(wrongChoice.waitForExistence(timeout: 5.0))
        wrongChoice.tap()
        Thread.sleep(forTimeInterval: 0.2)
        saveScreenshot("Quiz_Selected")

        // Check Answer -> Wrong Feedback
        app.buttons["Check"].tap()
        XCTAssertTrue(app.staticTexts["Keep going! You’re learning."].waitForExistence(timeout: 4.0))
        Thread.sleep(forTimeInterval: 0.4)
        saveScreenshot("Quiz_Wrong")
        app.buttons["Continue"].tap()

        // 13. Quiz Question 2 - Correct
        XCTAssertTrue(app.staticTexts["DAY 1"].waitForExistence(timeout: 4.0))
        let correctChoice = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Gentle and humble in heart'")).firstMatch
        XCTAssertTrue(correctChoice.waitForExistence(timeout: 5.0))
        correctChoice.tap()
        Thread.sleep(forTimeInterval: 0.2)
        app.buttons["Check"].tap()
        XCTAssertTrue(app.staticTexts["Correct!"].waitForExistence(timeout: 4.0))
        Thread.sleep(forTimeInterval: 0.4)
        saveScreenshot("Quiz_Correct")
        app.buttons["Continue"].tap()

        // Question 3 - Correct
        answer(app, "light")

        // 14. Lesson Complete Screen
        XCTAssertTrue(app.staticTexts["Day 1 complete"].waitForExistence(timeout: 6.0))
        XCTAssertTrue(app.staticTexts["+12 XP"].exists)
        XCTAssertTrue(app.staticTexts["1 day streak"].exists)
        Thread.sleep(forTimeInterval: 0.5)
        saveScreenshot("Lesson_Complete")
        app.buttons["Continue"].tap()

        // 15. Today after Day 1 (Home_Day1Done)
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 6.0))
        Thread.sleep(forTimeInterval: 0.4)
        saveScreenshot("Home_Day1Done")

        // 16. Bible Reader Tab
        ensureTabBarExpanded(app)
        app.tabBars.buttons["Bible"].tap()
        XCTAssertTrue(app.navigationBars["Genesis"].waitForExistence(timeout: 4.0))
        XCTAssertTrue(app.staticTexts["Chapter 1"].waitForExistence(timeout: 6.0))
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'in this sample'")).firstMatch.exists)
        Thread.sleep(forTimeInterval: 0.4)
        saveScreenshot("Bible_Reader")

        // Open Scripture Picker Sheet
        let bookPickerBtn = app.buttons["Select Book and Chapter"]
        if bookPickerBtn.exists {
            bookPickerBtn.tap()
            XCTAssertTrue(app.navigationBars["Select Scripture"].waitForExistence(timeout: 4.0))
            Thread.sleep(forTimeInterval: 0.3)
            saveScreenshot("Bible_Picker")
            app.navigationBars.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Close' OR label CONTAINS[c] 'xmark'")).firstMatch.tap()
        }

        // 17. Companion Tab
        ensureTabBarExpanded(app)
        app.tabBars.buttons["Lamb"].tap()
        XCTAssertTrue(app.navigationBars["Pip"].waitForExistence(timeout: 4.0))
        Thread.sleep(forTimeInterval: 0.4)
        saveScreenshot("Companion_Detail")

        // 18. Settings Tab
        ensureTabBarExpanded(app)
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 4.0))
        XCTAssertTrue(app.staticTexts["None"].exists)
        XCTAssertFalse(element(app, containing: "in v1").exists, "Settings still says 'in v1'")
        Thread.sleep(forTimeInterval: 0.3)
        saveScreenshot("Settings")

        // Restore Purchases Result Toast
        let restoreButton = app.buttons["Restore Purchases"]
        if restoreButton.exists {
            restoreButton.tap()
            let cancelBtn = app.buttons["Cancel"]
            if cancelBtn.waitForExistence(timeout: 2.0) {
                cancelBtn.tap()
            }
            Thread.sleep(forTimeInterval: 0.8)
            saveScreenshot("Settings_RestoreResult")
        }

        // Daily reminder: off by default; turning it on asks iOS once, then shows the time.
        let reminderSwitch = app.switches["Daily reminder"]
        XCTAssertTrue(reminderSwitch.waitForExistence(timeout: 4.0))
        XCTAssertEqual(reminderSwitch.value as? String, "0", "the reminder is on before the user asked")
        XCTAssertFalse(app.datePickers.firstMatch.exists)
        reminderSwitch.switches.firstMatch.tap()
        let allow = XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.buttons["Allow"]
        XCTAssertTrue(allow.waitForExistence(timeout: 5.0), "turning the reminder on did not ask for permission")
        allow.tap()
        XCTAssertTrue(app.datePickers.firstMatch.waitForExistence(timeout: 4.0))
        XCTAssertEqual(reminderSwitch.value as? String, "1")
        Thread.sleep(forTimeInterval: 0.4)
        saveScreenshot("Settings_Reminder")

        // 19. Terminate and Relaunch to Prove Persistence
        app.terminate()
        app.launch()

        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 6.0))
        XCTAssertFalse(app.staticTexts["Welcome to Pasture"].exists)
        Thread.sleep(forTimeInterval: 0.3)
    }

    @MainActor
    private func executeAX3Flow() throws {
        let app = XCUIApplication()
        app.launch()
        passOnboardingIfNeeded(app, reminderShot: "Accessibility_AX3_Reminder")

        let day1Node = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Day 1'")).firstMatch
        if day1Node.waitForExistence(timeout: 4.0) {
            day1Node.tap()
        }

        XCTAssertTrue(app.navigationBars["Day 1"].waitForExistence(timeout: 6.0))
        Thread.sleep(forTimeInterval: 0.4)
        saveScreenshot("Accessibility_AX3")

        app.swipeUp()
        let quizBtn = app.buttons["Take the quiz"]
        if quizBtn.waitForExistence(timeout: 3.0) {
            quizBtn.tap()
            _ = app.staticTexts["DAY 1"].waitForExistence(timeout: 4.0)
            let wrongChoice = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'religious leaders'")).firstMatch
            if wrongChoice.waitForExistence(timeout: 4.0) {
                wrongChoice.tap()
            }
            app.buttons["Check"].tap()
            _ = app.staticTexts["Keep going! You’re learning."].waitForExistence(timeout: 4.0)
            Thread.sleep(forTimeInterval: 0.4)
            saveScreenshot("Accessibility_AX3_QuizWrong")
        }
    }

    /// The reader row for verse `n` ("Verse 3, God said, …, Highlighted Yellow").
    @MainActor
    private func verse(_ app: XCUIApplication, _ n: Int) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "Verse \(n), ")).firstMatch
    }

    @MainActor
    private func savedRows(_ app: XCUIApplication, _ prefix: String) -> XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix))
    }

    @MainActor
    private func openGenesisOne(_ app: XCUIApplication) {
        passOnboardingIfNeeded(app)
        ensureTabBarExpanded(app)
        let bibleTab = app.tabBars.buttons["Bible"]
        XCTAssertTrue(bibleTab.waitForExistence(timeout: 6.0))
        bibleTab.tap()
        XCTAssertTrue(app.navigationBars["Genesis"].waitForExistence(timeout: 6.0))
        XCTAssertTrue(app.staticTexts["Chapter 1"].waitForExistence(timeout: 6.0))
        XCTAssertTrue(verse(app, 1).waitForExistence(timeout: 5.0))
    }

    /// Issue #13 end to end, with the review's repros: a selection that skips a verse (B1), a recolour
    /// inside a saved range (B2), Copy's text, every Saved filter, and jumping to the same item twice (N4).
    @MainActor
    private func executeBibleSavedFlow() throws {
        let app = XCUIApplication()
        let appearance = (modeOverride == "Dark") ? "dark" : "light"
        app.launchArguments += ["-appearance", appearance]
        app.launchArguments += ["-uitestCompleted", "beginner-30:1"]
        app.launchArguments += ["-uitestResetBibleUserData", "-uitestEchoCopy"]
        app.launch()
        openGenesisOne(app)
        Thread.sleep(forTimeInterval: 0.4)
        saveScreenshot("Bible_Reader")

        // B1: tap verse 1, then verse 3. Verse 2 joins the selection and the header names 1–3.
        verse(app, 1).tap()
        verse(app, 3).tap()
        let reference = app.staticTexts["SelectionReference"]
        XCTAssertTrue(reference.waitForExistence(timeout: 4.0), "Action menu should appear")
        XCTAssertEqual(reference.label, "Genesis 1:1–3")
        for n in 1...3 {
            XCTAssertTrue(verse(app, n).isSelected, "verse \(n) should be selected")
        }
        XCTAssertFalse(verse(app, 4).isSelected)
        Thread.sleep(forTimeInterval: 0.3)
        saveScreenshot("Bible_Reader_Selected")

        let yellowBtn = app.buttons["Highlight in Yellow"]
        XCTAssertTrue(yellowBtn.waitForExistence(timeout: 4.0))
        yellowBtn.tap()
        for n in 1...3 {
            XCTAssertTrue(verse(app, n).label.hasSuffix("Highlighted Yellow"), verse(app, n).label)
        }
        XCTAssertFalse(verse(app, 4).label.contains("Highlighted"))

        // B2: recolour only verse 2. Verses 1 and 3 keep their yellow highlight.
        verse(app, 2).tap()
        XCTAssertEqual(reference.label, "Genesis 1:2")
        app.buttons["Highlight in Rose"].tap()
        XCTAssertTrue(verse(app, 1).label.hasSuffix("Highlighted Yellow"), verse(app, 1).label)
        XCTAssertTrue(verse(app, 2).label.hasSuffix("Highlighted Rose"), verse(app, 2).label)
        XCTAssertTrue(verse(app, 3).label.hasSuffix("Highlighted Yellow"), verse(app, 3).label)
        Thread.sleep(forTimeInterval: 0.5)
        saveScreenshot("Bible_Reader_Highlighted")

        // Copy 1 and 3: the text carries all three verses, the reference and the attribution.
        verse(app, 1).tap()
        verse(app, 3).tap()
        app.buttons["CopyActionButton"].tap()
        let toast = app.descendants(matching: .any)["CopiedToast"]
        XCTAssertTrue(toast.waitForExistence(timeout: 3.0))
        let copied = toast.value as? String ?? ""
        XCTAssertTrue(copied.hasPrefix("In the beginning, God created the heavens and the earth. The earth was formless and empty."), copied)
        XCTAssertTrue(copied.contains("there was light."), copied)
        XCTAssertTrue(copied.hasSuffix("\n\nGenesis 1:1–3\nWorld English Bible"), copied)

        // Bookmark verse 3.
        verse(app, 3).tap()
        let bookmarkBtn = app.buttons["BookmarkActionButton"]
        XCTAssertTrue(bookmarkBtn.waitForExistence(timeout: 4.0))
        bookmarkBtn.tap()
        XCTAssertTrue(verse(app, 3).label.contains(", Bookmarked"), verse(app, 3).label)
        XCTAssertFalse(verse(app, 2).label.contains("Bookmarked"))

        // Note on verse 2.
        verse(app, 2).tap()
        let noteBtn = app.buttons["NoteActionButton"]
        XCTAssertTrue(noteBtn.waitForExistence(timeout: 4.0))
        noteBtn.tap()
        XCTAssertTrue(app.buttons["NoteCancelButton"].waitForExistence(timeout: 5.0), "Note sheet should appear")
        let textEditor = app.textViews["NoteTextEditor"]
        XCTAssertTrue(textEditor.waitForExistence(timeout: 3.0))
        textEditor.tap()
        textEditor.typeText("Formless and void before God speaks light into darkness.")
        Thread.sleep(forTimeInterval: 0.3)
        saveScreenshot("Bible_Note")
        app.buttons["NoteSaveButton"].tap()
        XCTAssertTrue(verse(app, 2).waitForExistence(timeout: 3.0))
        XCTAssertTrue(verse(app, 2).label.contains(", Has note"), verse(app, 2).label)

        // Saved: three highlight pieces, one bookmark, one note; each filter shows only its type.
        let savedBtn = app.buttons["Saved Scripture"]
        XCTAssertTrue(savedBtn.waitForExistence(timeout: 4.0))
        savedBtn.tap()
        XCTAssertTrue(app.navigationBars["Saved"].waitForExistence(timeout: 5.0))
        XCTAssertTrue(savedRows(app, "Note, Genesis 1:2").firstMatch.waitForExistence(timeout: 4.0))
        Thread.sleep(forTimeInterval: 0.4)
        saveScreenshot("Bible_Saved")

        app.buttons["Highlights"].tap()
        XCTAssertTrue(savedRows(app, "Highlight, Yellow, Genesis 1:1").firstMatch.waitForExistence(timeout: 3.0))
        XCTAssertTrue(savedRows(app, "Highlight, Rose, Genesis 1:2").firstMatch.exists)
        XCTAssertTrue(savedRows(app, "Highlight, Yellow, Genesis 1:3").firstMatch.exists)
        XCTAssertEqual(savedRows(app, "Highlight, ").count, 3)
        XCTAssertEqual(savedRows(app, "Bookmark, ").count, 0)
        XCTAssertEqual(savedRows(app, "Note, ").count, 0)

        app.buttons["Notes"].tap()
        XCTAssertTrue(savedRows(app, "Note, Genesis 1:2").firstMatch.waitForExistence(timeout: 3.0))
        XCTAssertEqual(savedRows(app, "Note, ").count, 1)
        XCTAssertEqual(savedRows(app, "Highlight, ").count, 0)
        XCTAssertEqual(savedRows(app, "Bookmark, ").count, 0)

        app.buttons["Bookmarks"].tap()
        let bookmarkRow = savedRows(app, "Bookmark, Genesis 1:3").firstMatch
        XCTAssertTrue(bookmarkRow.waitForExistence(timeout: 3.0))
        XCTAssertEqual(savedRows(app, "Bookmark, ").count, 1)
        XCTAssertEqual(savedRows(app, "Highlight, ").count, 0)
        XCTAssertEqual(savedRows(app, "Note, ").count, 0)

        // Jump back to the verse, scroll away, then open the same bookmark again (N4).
        for attempt in 1...2 {
            bookmarkRow.tap()
            XCTAssertTrue(app.navigationBars["Genesis"].waitForExistence(timeout: 5.0))
            let v3 = verse(app, 3)
            let deadline = Date().addingTimeInterval(4.0)
            while !v3.isHittable && Date() < deadline { Thread.sleep(forTimeInterval: 0.2) }
            XCTAssertTrue(v3.isHittable, "jump \(attempt) should bring verse 3 into view")
            guard attempt == 1 else { break }
            for _ in 0..<4 { app.swipeUp() }
            XCTAssertFalse(v3.isHittable, "verse 3 should be scrolled out of view before the second jump")
            savedBtn.tap()
            XCTAssertTrue(bookmarkRow.waitForExistence(timeout: 4.0))
        }
    }

    // MARK: - Issue #13 review B3: the verse action menu at AX3 text size
    @MainActor
    func testBibleActionMenuAX3Light() throws {
        modeOverride = "Light"
        try executeBibleActionMenuAX3()
    }

    @MainActor
    func testBibleActionMenuAX3Dark() throws {
        modeOverride = "Dark"
        try executeBibleActionMenuAX3()
    }

    /// At accessibility sizes the four actions stack one per line at full width, instead of four
    /// quarter-width columns whose labels break mid-word ("Book / mark", "Shar / e").
    @MainActor
    private func executeBibleActionMenuAX3() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-appearance", modeOverride == "Dark" ? "dark" : "light"]
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXL"]
        app.launchArguments += ["-uitestCompleted", "beginner-30:1", "-uitestResetBibleUserData"]
        app.launch()
        openGenesisOne(app)

        verse(app, 1).tap()
        let bookmark = app.buttons["BookmarkActionButton"]
        let note = app.buttons["NoteActionButton"]
        let copy = app.buttons["CopyActionButton"]
        let share = app.buttons["ShareActionButton"]
        XCTAssertTrue(share.waitForExistence(timeout: 4.0))
        Thread.sleep(forTimeInterval: 0.5)
        saveScreenshot("Bible_ActionMenu_AX3")

        let buttons = [bookmark, note, copy, share]
        let screenWidth = app.windows.firstMatch.frame.width
        for (upper, lower) in zip(buttons, buttons.dropFirst()) {
            XCTAssertGreaterThanOrEqual(lower.frame.minY, upper.frame.maxY - 1, "\(lower.identifier) should sit below \(upper.identifier)")
        }
        for button in buttons {
            XCTAssertGreaterThan(button.frame.width, screenWidth * 0.6, "\(button.identifier) should span the menu")
        }
    }
}
