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
    private func passOnboardingIfNeeded(_ app: XCUIApplication) {
        if app.staticTexts["Welcome to Shepherd"].exists {
            app.buttons["Continue"].tap()
            _ = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'peace'")).firstMatch.waitForExistence(timeout: 2.0)
            app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'peace'")).firstMatch.tap()
            app.buttons["Continue"].tap()
            _ = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Some experience'")).firstMatch.waitForExistence(timeout: 2.0)
            app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Some experience'")).firstMatch.tap()
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
            _ = app.buttons["See my plan"].waitForExistence(timeout: 2.0)
            app.buttons["See my plan"].tap()
            _ = app.buttons["Continue with free path"].waitForExistence(timeout: 2.0)
            app.buttons["Continue with free path"].tap()
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

    /// Tap the choice containing `text`, check it, and continue.
    @MainActor
    private func answer(_ app: XCUIApplication, _ text: String) {
        let choice = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 5.0), "no choice '\(text)'")
        choice.tap()
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

    /// Onboarding 'peace' follows Peace & Prayer (3 lessons in content today). Finishing them must
    /// show the path-complete state, not the last day again, and lead to the catalog.
    @MainActor
    private func executePathCompleteFlow() throws {
        let app = XCUIApplication()
        app.launch()
        passOnboardingIfNeeded(app)
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 6.0))

        completeLesson(app, day: 1, answers: ["All you who labor", "Gentle and humble in heart", "light"])
        completeLesson(app, day: 2, answers: ["feeds", "The birds of the sky", "moment"])
        completeLesson(app, day: 3, answers: ["strength", "Be still, and know that I am God", "Be afraid"])

        XCTAssertTrue(app.staticTexts["Path complete"].waitForExistence(timeout: 6.0))
        XCTAssertFalse(app.buttons["Day 3, current"].exists, "the finished path offers its last day again")
        Thread.sleep(forTimeInterval: 0.4)
        saveScreenshot("Home_PathComplete")

        let next = app.buttons["Choose your next path"]
        XCTAssertTrue(next.exists)
        next.tap()
        XCTAssertTrue(app.navigationBars["Paths"].waitForExistence(timeout: 4.0))
        XCTAssertTrue(element(app, containing: "3 of 3 done").exists)
        Thread.sleep(forTimeInterval: 0.3)
        saveScreenshot("Path_Overview_AfterComplete")
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
            XCTAssertTrue(app.staticTexts["Keep going! You're learning."].waitForExistence(timeout: 4.0))
            Thread.sleep(forTimeInterval: 2.0)
        }
    }

    @MainActor
    private func executeRealAppFlow() throws {
        let app = XCUIApplication()
        app.launch()

        // 1. Onboarding Step 0: Welcome
        XCTAssertTrue(app.staticTexts["Welcome to Shepherd"].waitForExistence(timeout: 6.0))
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

        // 6. Onboarding Step 5: Building Plan
        XCTAssertTrue(app.staticTexts["Preparing your path…"].waitForExistence(timeout: 4.0))
        // goal 'peace' -> Peace & Prayer, and the screen says honestly that it is Premium
        XCTAssertTrue(element(app, containing: "Peace & Prayer: 14 Days").exists)
        XCTAssertTrue(element(app, containing: "Premium · first 3 lessons free").exists)
        Thread.sleep(forTimeInterval: 0.3)
        saveScreenshot("Onboarding_BuildingPlan")
        app.buttons["See my plan"].tap()

        // 7. Paywall
        XCTAssertTrue(app.staticTexts["Start your 7-day free trial"].waitForExistence(timeout: 6.0))
        // Both Premium paths hold only their free preview lessons today, so Premium claims no lessons.
        XCTAssertTrue(app.staticTexts["Premium unlocks: streak freezes"].exists)
        XCTAssertFalse(element(app, containing: "Premium lesson").exists)
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
        Thread.sleep(forTimeInterval: 0.4)
        saveScreenshot("Lesson_Reading")

        // Scroll down to "Take the quiz"
        app.swipeUp()
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
        XCTAssertTrue(app.staticTexts["Keep going! You're learning."].waitForExistence(timeout: 4.0))
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

        // 19. Terminate and Relaunch to Prove Persistence
        app.terminate()
        app.launch()

        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 6.0))
        XCTAssertFalse(app.staticTexts["Welcome to Shepherd"].exists)
        Thread.sleep(forTimeInterval: 0.3)
    }

    @MainActor
    private func executeAX3Flow() throws {
        let app = XCUIApplication()
        app.launch()
        passOnboardingIfNeeded(app)

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
            _ = app.staticTexts["Keep going! You're learning."].waitForExistence(timeout: 4.0)
            Thread.sleep(forTimeInterval: 0.4)
            saveScreenshot("Accessibility_AX3_QuizWrong")
        }
    }
}
