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

    /// Open Today's current lesson for `day`, answer its quiz and leave the Lesson Complete
    /// screen, which leads to the reflection step.
    @MainActor
    private func finishLessonQuiz(_ app: XCUIApplication, day: Int, answers: [String]) {
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
    }

    /// Skip the optional reflection step that follows Lesson Complete, back to Today.
    @MainActor
    private func skipReflection(_ app: XCUIApplication) {
        XCTAssertTrue(app.staticTexts["Reflect & Pray"].waitForExistence(timeout: 6.0), "no reflection step after the lesson")
        app.buttons["SkipReflectionButton"].tap()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 6.0))
    }

    /// Open Today's current lesson for `day`, answer its quiz and skip the reflection.
    @MainActor
    private func completeLesson(_ app: XCUIApplication, day: Int, answers: [String]) {
        finishLessonQuiz(app, day: day, answers: answers)
        skipReflection(app)
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
        app.launchArguments += ["-uitestCompleted", "beginner-30:29"]
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

    /// Days 1-2 seeded; Day 3 played with a perfect quiz. The rating sheet appears on Today, and a
    /// cold relaunch does not ask again.
    @MainActor
    func testReviewPromptAfterPerfectDay3() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uitestReset", "-uitestCompleted", "beginner-30:2"]
        app.launch()
        passOnboardingIfNeeded(app, goal: "Grow a daily habit", level: "Brand new")
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 6.0))
        completeLesson(app, day: 3, answers: ["Word", "Flesh"])
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
        completeLesson(app, day: 3, answers: ["Law", "Flesh"])
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
        skipReflection(app)

        // 15. Today after Day 1 (Home_Day1Done)
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

        // The Journal at AX sizes: the prayer filter is a menu, not a row of pills
        app.terminate()
        app.launchArguments += ["-uitestReset"]
        app.launch()
        passOnboardingIfNeeded(app)
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 6.0))
        ensureTabBarExpanded(app)
        app.tabBars.buttons["Settings"].tap()
        let settingsJournalButton = app.buttons["SettingsJournalButton"]
        for _ in 0..<6 where !settingsJournalButton.isHittable {
            app.swipeUp()
        }
        settingsJournalButton.tap()
        XCTAssertTrue(app.navigationBars["Journal"].waitForExistence(timeout: 6.0))
        XCTAssertTrue(app.staticTexts["No reflections yet"].waitForExistence(timeout: 4.0))
        Thread.sleep(forTimeInterval: 0.4)
        saveScreenshot("Accessibility_AX3_Journal")

        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Prayers'")).firstMatch.tap()
        let addPrayerField = app.textFields["Add a prayer request…"]
        XCTAssertTrue(addPrayerField.waitForExistence(timeout: 4.0))
        addPrayerField.tap()
        addPrayerField.typeText("Healing for Anna after surgery\n")
        XCTAssertTrue(app.buttons["PrayerFilterMenu"].waitForExistence(timeout: 4.0), "no filter menu at AX sizes")
        XCTAssertFalse(app.buttons["Open (1)"].exists, "filter pills at AX sizes")
        if app.keyboards.firstMatch.exists {
            app.swipeDown()
        }
        Thread.sleep(forTimeInterval: 0.4)
        saveScreenshot("Accessibility_AX3_Prayers")
    }

    // MARK: - Issue #17: Reflection and Prayer Journal UI Tests

    @MainActor
    func testJournalAndReflectionLight() throws {
        modeOverride = "Light"
        try executeJournalFlow()
    }

    @MainActor
    func testJournalAndReflectionDark() throws {
        modeOverride = "Dark"
        try executeJournalFlow()
    }

    /// `-uitestReset` starts from a fresh install's state (empty journal, lock off);
    /// `-uitestJournalAuth yes,no,yes` answers the three owner checks below in turn (enable the
    /// lock, the automatic check on reopening, the Unlock button).
    @MainActor
    private func executeJournalFlow() throws {
        let app = XCUIApplication()
        let appearance = (modeOverride ?? "Light").lowercased()
        let keepStateArgs = ["-appearance", appearance, "-uitestJournalAuth", "yes,no,yes"]
        app.launchArguments += ["-uitestReset"] + keepStateArgs
        app.launch()
        passOnboardingIfNeeded(app, goal: "Grow a daily habit", level: "Brand new")
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 6.0))

        // 1. Day 1: the lesson is recorded before the reflection step, so quitting there keeps it
        finishLessonQuiz(app, day: 1, answers: ["God", "Let there be light"])
        XCTAssertTrue(app.staticTexts["Reflect & Pray"].waitForExistence(timeout: 6.0))
        XCTAssertFalse(app.buttons["SaveReflectionButton"].isEnabled, "an empty reflection can be saved")
        Thread.sleep(forTimeInterval: 0.5)
        saveScreenshot("Lesson_Reflection")
        app.terminate()
        app.launchArguments = keepStateArgs // a cold launch keeping today's progress
        app.launch()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 6.0))
        XCTAssertTrue(app.buttons["Day 2, current"].waitForExistence(timeout: 6.0), "quitting at the reflection step lost Day 1")

        // 2. Day 2: write and save a reflection
        let reflection = "Made in his image, I can rest in how he sees me."
        finishLessonQuiz(app, day: 2, answers: ["God’s", "Male and female"])
        XCTAssertTrue(app.staticTexts["Reflect & Pray"].waitForExistence(timeout: 6.0))
        let editor = app.textViews["ReflectionTextEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 4.0))
        editor.tap()
        editor.typeText(reflection)
        let saveButton = app.buttons["SaveReflectionButton"]
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 6.0))
        XCTAssertTrue(app.buttons["Day 3, current"].waitForExistence(timeout: 6.0))

        // 3. Lamb tab -> Journal lists the saved reflection, tagged with its lesson
        ensureTabBarExpanded(app)
        app.tabBars.buttons["Lamb"].tap()
        let journalButton = app.buttons["CompanionJournalButton"]
        XCTAssertTrue(journalButton.waitForExistence(timeout: 4.0))
        journalButton.tap()
        XCTAssertTrue(app.navigationBars["Journal"].waitForExistence(timeout: 6.0))
        XCTAssertTrue(element(app, containing: reflection).waitForExistence(timeout: 4.0), "the saved reflection is not in the Journal")
        XCTAssertTrue(element(app, containing: "Made in God's image").exists)

        // A reflection written from the Journal itself
        app.buttons["New Reflection"].tap()
        XCTAssertTrue(app.navigationBars["New Reflection"].waitForExistence(timeout: 4.0))
        app.textFields["Title or passage (optional)"].tap()
        app.textFields["Title or passage (optional)"].typeText("Psalm 23")
        app.textViews.firstMatch.tap()
        app.textViews.firstMatch.typeText("The Lord is my shepherd; I shall lack nothing.")
        app.buttons["Save to Journal"].tap()
        XCTAssertTrue(element(app, containing: "I shall lack nothing").waitForExistence(timeout: 4.0))
        Thread.sleep(forTimeInterval: 0.5)
        saveScreenshot("Journal_Entries")

        // By path: one section for the First Steps path, one for reflections not tied to a lesson
        app.buttons["ReflectionGroupingMenu"].tap()
        let byPath = app.buttons["By path"]
        XCTAssertTrue(byPath.waitForExistence(timeout: 3.0))
        byPath.tap()
        XCTAssertTrue(app.staticTexts["FIRST STEPS: 30 DAYS WITH GOD"].waitForExistence(timeout: 4.0))
        XCTAssertTrue(app.staticTexts["YOUR OWN REFLECTIONS"].exists)
        Thread.sleep(forTimeInterval: 0.4)
        saveScreenshot("Journal_ByPath")

        // 4. Prayers: one open, one answered, and the filters
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Prayers'")).firstMatch.tap()
        let addPrayerField = app.textFields["Add a prayer request…"]
        XCTAssertTrue(addPrayerField.waitForExistence(timeout: 3.0))
        addPrayerField.tap()
        addPrayerField.typeText("Healing for Anna after surgery\n")
        addPrayerField.tap()
        addPrayerField.typeText("Peace and guidance for the week\n")
        XCTAssertTrue(app.buttons["All (2)"].waitForExistence(timeout: 3.0))
        // Newest first: this marks "Peace and guidance for the week" answered
        app.buttons.matching(NSPredicate(format: "label == 'Mark as answered'")).firstMatch.tap()
        XCTAssertTrue(app.buttons["Open (1)"].waitForExistence(timeout: 3.0))
        XCTAssertTrue(app.buttons["Answered (1)"].exists)
        XCTAssertTrue(element(app, containing: "Answered ").exists, "no answered date")

        app.buttons["Open (1)"].tap()
        XCTAssertTrue(element(app, containing: "Healing for Anna").waitForExistence(timeout: 3.0))
        XCTAssertFalse(element(app, containing: "Peace and guidance").exists, "the Open filter shows an answered prayer")
        app.buttons["Answered (1)"].tap()
        XCTAssertTrue(element(app, containing: "Peace and guidance").waitForExistence(timeout: 3.0))
        XCTAssertFalse(element(app, containing: "Healing for Anna").exists, "the Answered filter shows an open prayer")
        app.buttons["All (2)"].tap()
        XCTAssertTrue(element(app, containing: "Healing for Anna").waitForExistence(timeout: 3.0))
        Thread.sleep(forTimeInterval: 0.5)
        saveScreenshot("Journal_Prayers")

        // 5. Turn the lock on (owner check 1: yes)
        app.buttons["Journal Privacy Settings"].tap()
        let lockSwitch = app.switches.firstMatch
        XCTAssertTrue(lockSwitch.waitForExistence(timeout: 4.0))
        lockSwitch.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["Lock Journal Now"].waitForExistence(timeout: 4.0), "the lock did not turn on")
        app.navigationBars["Journal Privacy"].buttons["Done"].tap()

        // Leaving the journal locks it: reopening asks again (owner check 2: no)
        app.navigationBars["Journal"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(journalButton.waitForExistence(timeout: 4.0))
        journalButton.tap()
        XCTAssertTrue(app.staticTexts["Journal Locked"].waitForExistence(timeout: 4.0), "the journal stayed unlocked after leaving it")
        XCTAssertFalse(element(app, containing: reflection).exists)
        XCTAssertFalse(app.buttons["New Reflection"].exists, "the add button is live on the locked screen")
        Thread.sleep(forTimeInterval: 0.4)
        saveScreenshot("Journal_Locked")

        // Unlock (owner check 3: yes)
        app.buttons["Unlock Journal"].tap()
        XCTAssertTrue(element(app, containing: reflection).waitForExistence(timeout: 4.0))

        // Backgrounding the app locks it again
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 2.0)
        app.activate()
        XCTAssertTrue(app.staticTexts["Journal Locked"].waitForExistence(timeout: 4.0), "the journal stayed unlocked after backgrounding")
        XCTAssertFalse(element(app, containing: reflection).exists)

        // 6. The Journal is also reachable from Settings
        ensureTabBarExpanded(app)
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 4.0))
        let settingsJournalButton = app.buttons["SettingsJournalButton"]
        XCTAssertTrue(settingsJournalButton.waitForExistence(timeout: 4.0))
        settingsJournalButton.tap()
        XCTAssertTrue(app.navigationBars["Journal"].waitForExistence(timeout: 4.0))
    }
}
