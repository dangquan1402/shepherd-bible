# App Store screenshots

Pasture's iPhone 6.9" App Store screenshots (1320 x 2868, portrait; ASC display type `APP_IPHONE_67`),
framed with goldie 0.2.1 in Green Pastures colours (`tools/brand/tokens.py` direction `pasture`:
canvas `#F9F8F3` into accent-subtle `#DCF5EB`, ink `#16231C`, subline `#47534C`; headline DM Sans, bundled with goldie).
`screenshots/contact-sheet.png` shows them in listing order.

| # | File | Capture (RealFlowUITests) | Headline | Subline |
|---|---|---|---|---|
| 1 | `01-today.png` | `Home_DailyPath_Light` | A little Bible, every day | Short guided lessons on a path you can follow |
| 2 | `02-lesson.png` | `Lesson_Reading_Light` | Scripture, plainly explained | A passage, a short reflection and a prayer |
| 3 | `03-quiz.png` | `Quiz_Correct_Light` | Every answer shows its verse | A quick quiz after each lesson |
| 4 | `04-complete.png` | `Lesson_Complete_Dark` | Watch your lamb grow | Earn XP and keep your day streak |
| 5 | `05-lamb.png` | `Companion_Detail_Light` | Name your lamb | Five stages, from Newborn to Grown sheep |
| 6 | `06-paths.png` | `Path_Overview_Light` | Three paths, 74 lessons | First Steps is free. Premium paths: first 3 free |
| 7 | `07-bible.png` | `Bible_Reader_Dark` | The whole Bible, offline | All 66 books of the World English Bible |
| 8 | `08-widgets.png` | `testWidgetsOnHomeScreenUpdateAfterLesson`, then the Home Screen via `simctl io screenshot` | Your verse on the Home Screen | Widgets for your daily verse and streak |

The product page header and search results creative assets (uploaded by hand in App Store Connect) live in `header/`;
see `header/README.md`.

`review/paywall-review.png` (`Paywall_Trial_Light`, raw) is the App Store review screenshot of both subscriptions
(monthly and yearly).

## Regenerate

1. Create and boot a fresh iPhone 17 Pro Max simulator (iOS 26); pin the status bar:
   `xcrun simctl status_bar <udid> override --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100`.
2. `xcodebuild build-for-testing ... -derivedDataPath <dd>`, then copy the `.xctestrun` with `SHOT_DIR` pointed at a
   scratch dir (the scheme's `SHOT_DIR` wins over `TEST_RUNNER_SHOT_DIR` and would overwrite `docs/screenshots`).
3. Run each test with `test-without-building -xctestrun <copy> -only-testing:...`, `simctl uninstall` the app before each
   (the full flows need a fresh install). `testRealAppFullFlowDark` follows the simulator's appearance: run
   `simctl ui <udid> appearance dark` first.
4. Frame 8: after the widget test, `simctl uninstall` the `com.dangvietquan.shepherdUITests.xctrunner` app (its icon
   shows on the Home Screen), re-pin the status bar and `simctl io <udid> screenshot Widgets_HomeScreen_Clean_Light.png`.
5. `python3 -I docs/appstore/stage_raw.py <shots dir> <work dir>`, then `goldie frame` and `goldie verify --device iphone-6.9`
   in the work dir. Open every PNG.
6. `asc --profile LittleRed screenshots validate --path "$(pwd -P)/docs/appstore/screenshots/iphone-6.9" --device-type IPHONE_69`,
   then `screenshots upload --app 6819303372 --version-id <id> --locale en-US --path ... --device-type IPHONE_69`
   (add `--replace --confirm` when the set already has screenshots). The path must not be a symlink.
