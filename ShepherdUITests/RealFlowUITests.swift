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
            _ = app.buttons["Continue"].waitForExistence(timeout: 2.0)
            app.buttons["Continue"].tap()
            _ = app.buttons["See my plan"].waitForExistence(timeout: 2.0)
            app.buttons["See my plan"].tap()
            _ = app.buttons["Continue with free path"].waitForExistence(timeout: 2.0)
            app.buttons["Continue with free path"].tap()
        }
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

        let johnRow = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'John'")).firstMatch
        XCTAssertTrue(johnRow.waitForExistence(timeout: 4.0))
        johnRow.tap()

        let ch1 = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Chapter 1'")).firstMatch
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

        app.tabBars.buttons["Lamb"].tap()
        let lambBar = app.navigationBars.matching(NSPredicate(format: "label CONTAINS[c] 'Pip' OR label CONTAINS[c] 'Lamb'")).firstMatch
        XCTAssertTrue(lambBar.waitForExistence(timeout: 4.0))

        Thread.sleep(forTimeInterval: 1.0)
        app.scrollViews.otherElements.firstMatch.tap()
        Thread.sleep(forTimeInterval: 2.0)
    }

    @MainActor
    func testRecordCheckMorph() throws {
        let app = XCUIApplication()
        app.launch()
        passOnboardingIfNeeded(app)

        let day1Node = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Day 1'")).firstMatch
        if day1Node.waitForExistence(timeout: 4.0) {
            day1Node.tap()
        }
        app.swipeUp()
        let quizBtn = app.buttons["Take the quiz"]
        if quizBtn.waitForExistence(timeout: 3.0) {
            quizBtn.tap()
            _ = app.staticTexts["DAY 1"].waitForExistence(timeout: 4.0)
            let wrongChoice = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Angels'")).firstMatch
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
        Thread.sleep(forTimeInterval: 0.3)
        saveScreenshot("Onboarding_BuildingPlan")
        app.buttons["See my plan"].tap()

        // 7. Paywall
        XCTAssertTrue(app.staticTexts["Start your 7-day free trial"].waitForExistence(timeout: 6.0))
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

        // Select Choice ("Angels" - wrong)
        let wrongChoice = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Angels'")).firstMatch
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
        let correctChoice = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Let there be light'")).firstMatch
        XCTAssertTrue(correctChoice.waitForExistence(timeout: 5.0))
        correctChoice.tap()
        Thread.sleep(forTimeInterval: 0.2)
        app.buttons["Check"].tap()
        XCTAssertTrue(app.staticTexts["Correct!"].waitForExistence(timeout: 4.0))
        Thread.sleep(forTimeInterval: 0.4)
        saveScreenshot("Quiz_Correct")
        app.buttons["Continue"].tap()

        // 14. Lesson Complete Screen
        XCTAssertTrue(app.staticTexts["Day 1 complete"].waitForExistence(timeout: 6.0))
        XCTAssertTrue(app.staticTexts["+11 XP"].exists)
        XCTAssertTrue(app.staticTexts["1 day streak"].exists)
        Thread.sleep(forTimeInterval: 0.5)
        saveScreenshot("Lesson_Complete")
        app.buttons["Continue"].tap()

        // 15. Today after Day 1 (Home_Day1Done)
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 6.0))
        Thread.sleep(forTimeInterval: 0.4)
        saveScreenshot("Home_Day1Done")

        // 16. Bible Reader Tab
        app.tabBars.buttons["Bible"].tap()
        XCTAssertTrue(app.navigationBars["Genesis"].waitForExistence(timeout: 4.0))
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
        app.tabBars.buttons["Lamb"].tap()
        XCTAssertTrue(app.navigationBars["Pip"].waitForExistence(timeout: 4.0))
        Thread.sleep(forTimeInterval: 0.4)
        saveScreenshot("Companion_Detail")

        // 18. Settings Tab
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 4.0))
        Thread.sleep(forTimeInterval: 0.3)
        saveScreenshot("Settings")

        // Restore Purchases Result Toast
        let restoreButton = app.buttons["Restore Purchases"]
        if restoreButton.exists {
            restoreButton.tap()
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

        // Navigate to Day 1 lesson (either via Day 1 node or onboarding if clean)
        let welcome = app.staticTexts["Welcome to Shepherd"]
        if welcome.exists {
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
            _ = app.buttons["Continue"].waitForExistence(timeout: 2.0)
            app.buttons["Continue"].tap()
            _ = app.buttons["See my plan"].waitForExistence(timeout: 2.0)
            app.buttons["See my plan"].tap()
            _ = app.buttons["Continue with free path"].waitForExistence(timeout: 2.0)
            app.buttons["Continue"].tap()
        }

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
            let wrongChoice = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Angels'")).firstMatch
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
