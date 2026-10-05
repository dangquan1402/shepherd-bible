## Summary

This PR implements the Shepherd iOS 26 Liquid Glass redesign end-to-end in SwiftUI, stacked directly on `fm/sb-design` (PR #1). Shepherd is a privacy-first, Duolingo-style Bible learning app with an animated lamb companion, on-device SwiftData persistence, and StoreKit 2 subscriptions.

The app is fully buildable, testable, and verified with zero errors and zero warnings introduced.

## Architecture & Implementation Highlights

- **Project & Tooling (`project.yml`):**
  - Generated via XcodeGen (`Shepherd.xcodeproj` committed).
  - Target: iOS 26.0 deployment target, iPhone only (`TARGETED_DEVICE_FAMILY: "1"`), Bundle ID `com.dangvietquan.shepherd`.
  - Configured `ITSAppUsesNonExemptEncryption: false`, `CFBundleVersion: $(CURRENT_PROJECT_VERSION)`, and `Shepherd.storekit` test scheme integration.
  - Complete `Assets.xcassets` catalog with `AccentColor`, `AppIcon`, `TabLamb` template icon, and Light/Dark token sets for every design token.
- **Native Vector Lamb Mascot System (`LambSystem.swift`):**
  - Rendered entirely with native vector SwiftUI Shapes/Paths — NO emoji, NO static PNGs.
  - Supports 5 developmental stages (`LambStage`: Lamb, Scout, Yearling, Guardian, Elder) across 6 expressions (`LambExpression`: idle, happy, encouraging, celebrating, stageUp, resting).
  - Scale-adaptive geometry rendering crisp vector art at 24pt, 56pt, 88pt, and 180pt+.
- **Calm Liquid Glass Motion (14-Row Motion Table):**
  - Row 1: Idle breathe loop (3.2s loop, easeInOut duration 1.6s).
  - Row 2: Idle blink keyframes (0.15s cubic squash keyframes).
  - Row 3: Happy hop (snappy spring, -12pt keyframe offset with 0.94 squash on landing).
  - Row 4: Encouraging tilt (0 to 10° spring tilt on correct answer).
  - Row 5: Celebrate sparkles (sparkle bursts on lesson completion).
  - Row 6: Stage-up morph.
  - Row 7: Quiz Check button -> feedback sheet morph using `GlassEffectContainer` + `glassEffectID` + `@Namespace`.
  - Row 8: Accessory card `.tabBarMinimizeBehavior(.onScrollDown)` with `tabViewBottomAccessoryPlacement`.
  - Row 9: Path node -> Lesson zoom navigation transition via `.matchedTransitionSource` and `.navigationTransition(.zoom)`.
  - Row 10: Streak chip numericText bounce + `.sensoryFeedback`.
  - Row 11: XP fill bar easeInOut animation.
  - Row 12: Node unlock transition.
  - Row 13: System scroll edge effect (`.scrollEdgeEffectStyle(.soft)`).
  - Row 14: System haptics (`sensoryFeedback(.success)` / `.warning`).
  - Full respect for `accessibilityReduceMotion` and `accessibilityReduceTransparency` fallbacks.
- **Flows & Screens Per Design:**
  - **Onboarding:** Multi-step flow (Welcome -> Goal -> Experience -> Daily Pace -> Name Companion -> Building Plan) persisting answers to SwiftData.
  - **Today Path:** S-curve meadow trail with 3D embossed path nodes (done, current, locked, milestone), lamb companion speech bubble, streak counter, and lesson accessory card.
  - **Path Catalogue & Lesson List:** Beginner 7-day path + honest "More paths are coming" card.
  - **Lesson Reading & Quiz:** Public-domain WEB scripture reading, prayer prompt, multi-choice quiz with M5 answering verse lookup, and morphing feedback sheet.
  - **Lesson Complete Reward:** XP calculation (+10 base + quiz score), streak increment, animated lamb celebration, and stage-up transition.
  - **Companion View:** Stage timeline, XP progress to next stage, and interactive renaming sheet.
  - **Bible Reader & Book/Chapter Picker:** Offline WEB Genesis reader with verse-gap markers.
  - **Settings:** Zero-telemetry on-device privacy declaration, StoreKit restore purchases, and version info.
  - **StoreKit 2 Paywall:** Yearly/Monthly subscriptions with 7-day trial intro offers, real-time `displayPrice`, trial auto-renew disclosure, full state machine (`idle`, `purchasing`, `pending`, `failed`, `restored`), and free path bypass.

## Verification & Test Results

### 1. Build & Test Execution
- **`xcodebuild build`**: `** BUILD SUCCEEDED **` (0 errors, 0 warnings).
- **`xcodebuild test`**: `** TEST SUCCEEDED **` (6/6 passing in 0.028s):
  - `testXPEarnedCalculation`: Verifies XP earned = 10 + quiz score.
  - `testStageProgression`: Verifies stage = 1 + xp/50 capped at 5.
  - `testStreakProgression`: Verifies day 1 streak = 1, consecutive day +1, and gap resets to 1.
  - `testExplainAndVerseSelectionRule`: Verifies M5 answering verse lookup finds matching scripture text.
  - `testOnboardingAnswersPersistence`: Verifies SwiftData user profile and companion models persist across sessions.
  - `testEntitlementGating`: Verifies StoreKitTest entitlement state gating for locked vs unlocked features.
- **Proof Tests Bite (Rule 9):**
  - Mutated each logic function (e.g. XP = 5 + score, stage cap = 4, streak ignoring day gap, broken verse selection, inverted entitlement gating) and confirmed each test failed immediately before restoring expected logic.

### 2. Archive Sanity Check
Release build inspected:
- `Assets.car` compiled and linked in root bundle.
- `AppIcon` rendered at 1024x1024 and present.
- Bundled resources verified: `paths.json`, `sample_bible.json`, `lamb_variants.json`.
- Plist properties confirmed: `ITSAppUsesNonExemptEncryption = false`, `UIDeviceFamily = [1]`.

### 3. Headless Simulator Runtime Verification
Executed on dedicated headless cloned simulator (`xcrun simctl`):
- Captured 56 pixel-accurate screenshots (28 Light + 28 Dark) under `docs/screenshots/`.
- Recorded motion clips (`Motion_LambHop.mp4`, `Motion_CheckMorph.mp4`) and 3 sequential animation frames each under `docs/screenshots/`.
- Verified StoreKit purchasing, pending, failed, and restored states.
- Dedicated simulator device was shut down and deleted cleanly upon completion.

## Deviations & Self-Grade

- **Deviations:**
  - Standard SF Pro / New York serif typography used instead of proprietary external fonts.
  - App icon is a Stage 3 Happy Lamb vector render on amber/meadow backdrop (marked placeholder per brief).
  - Terms of Service and Privacy Policy URLs in `StoreKitManager.swift` are placeholder URLs marked TODO for captain follow-up.
- **Self-Grade:** A- (full native implementation matching Pencil specs, complete motion table, verified StoreKit 2 & SwiftData flows, clean test bite proof).

## Captain Follow-up
- Replace placeholder URLs in `StoreKitManager.swift` (`https://shepherd.bible/terms`, `https://shepherd.bible/privacy`) with production endpoints before App Store submission.
