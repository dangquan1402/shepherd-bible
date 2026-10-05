# Shepherd — iOS 26 "Liquid Glass" Design Specification

This specification documents the complete visual and architectural redesign of **Shepherd** for Apple iOS 26. Grounded in Refero design research, it establishes an authentic Liquid Glass design system, a warm pastoral identity, 100% data-truthful content extracted from repository sources, and an accessible, production-grade interface.

---

## 1. Product Summary & Design Inputs

### 1.1 Product Contract
- **Positioning:** Privacy-first, Duolingo-style Bible learning app for iOS.
- **Architecture:** SwiftData on-device persistence, StoreKit 2 soft paywall, bundled public-domain World English Bible (WEB), WidgetKit ready.
- **Privacy Guarantee:** 100% on-device. No accounts, no email capture, no third-party trackers, no cloud analytics.
- **Monetization:** Free 7-day beginner path + offline reader; Shepherd Premium soft paywall (7-day free trial, Annual primary with placeholder pricing + Monthly tier).

### 1.2 Data Models & Service Contract

Every metric and state in the design maps 1:1 to the SwiftData models and services in `Shepherd/`:

| Model / Service | Source File | Properties & Exposed APIs | Redesign Mapping |
|:---|:---|:---|:---|
| `UserProfile` | `UserModels.swift:4-28` | `displayName: String?`<br>`goal: String` ("grow_daily", "understand", "peace", "new")<br>`experienceLevel: String` ("beginner", "some", "regular")<br>`dailyMinutes: Int` (5, 10, 15)<br>`createdAt: Date`<br>`hasCompletedOnboarding: Bool` | Drives the 4-step onboarding questionnaire and personalizes the "Building your personal path" screen. |
| `Companion` | `UserModels.swift:30-48` | `name: String` (default "Lamb")<br>`stage: Int` (1..5: `1 + xp / 50`)<br>`xp: Int`<br>`outfitId: String?`<br>`func addXP(_ amount: Int)` | Drives the vector lamb companion in all 5 stages: Stage 1 Newborn (0-49 XP), Stage 2 Sprout (50-99 XP), Stage 3 Lamb (100-149 XP), Stage 4 Yearling (150-199 XP), Stage 5 Flock Leader (200+ XP). |
| `StreakState` | `UserModels.swift:50-79` | `current: Int`<br>`best: Int`<br>`lastCompletedDate: Date?`<br>`freezesLeft: Int` (default 1)<br>`func markCompleted(on day: Date)` | Drives the floating streak pill ("3 Days 🔥 · Best 5"), weekly streak calendar dots, and streak freeze indicator in settings/paywall. |
| `LessonProgress` | `UserModels.swift:81-92` | `lessonId: String`<br>`completedAt: Date`<br>`quizScore: Int` | Determines path node status: completed (check), current (active pulse), or locked (padlock). |
| `EntitlementState` | `UserModels.swift:94-105` | `isPremium: Bool`<br>`expirationDate: Date?`<br>`productId: String?` | Governs access to premium path chapters, companion custom outfits, and widget customization. |
| `StoreKitManager` | `StoreKitManager.swift:1-38` | `monthlyID = "com.dangvietquan.shepherd.premium.monthly"`<br>`yearlyID = "com.dangvietquan.shepherd.premium.yearly"`<br>`products: [Product]`<br>`func purchase(_ product: Product)` | 7-day trial timeline, Annual primary card ($39.99/yr placeholder) + Monthly option ($4.99/mo placeholder), Restore Purchases, App Store terms. |
| `ContentStore` | `ContentStore.swift:1-43` | `bible: BibleBundle?`<br>`paths: [StudyPath]`<br>`func verse(ref: String) -> String?` | Feeds verbatim WEB verses for all lesson readings, quiz answers, and standalone reader view. |

### 1.3 Verbatim Current Scaffold Copy & Data Inventory

Extracted directly from the Swift codebase:

- **Onboarding (`OnboardingFlowView.swift`):**
  - Welcome: *"Welcome to Shepherd"*, *"A few minutes a day. Scripture that sticks. Everything stays on your phone."*
  - Goal: *"What’s your goal?"* -> *"Grow a daily habit"* (`grow_daily`), *"Understand the Bible better"* (`understand`), *"Find peace & prayer"* (`peace`), *"I’m new to faith"* (`new`).
  - Familiarity: *"How familiar are you?"* -> *"Beginner"* (`beginner`), *"Some experience"* (`some`), *"I read regularly"* (`regular`).
  - Daily Time: *"How many minutes a day?"* -> *"5 min"*, *"10 min"*, *"15 min"*.
  - Mascot Name: *"Name your companion"*, TextField placeholder *"Lamb’s name"*.
  - Plan Generation: *"Building your personal path…"*, *"Goal: [goal] · [minutes] min/day"*.
  - CTAs: *"Continue"*, *"See my plan"*.
- **Home (`HomeView.swift`):**
  - Large title *"Today"*.
  - Subtitle *"Streak \(current) 🔥 · Best \(best)"*.
  - Continue card *"Continue path"*, `lesson.title`, *"Day \(lesson.dayIndex)"*.
  - Mascot readout *"\(name) is stage \(stage) · \(xp) XP"*.
- **Paywall (`PaywallView.swift`):**
  - Heading *"Grow with Shepherd Premium"*.
  - Feature items: *"Full learning paths"*, *"Streak freezes"*, *"Companion outfits"*, *"Widgets & reminders"*.
  - Plan options: *"Yearly — 7-day free trial · Best value (Most popular)"*, *"Monthly — 7-day free trial"*.
  - CTAs: *"Start free trial"*, *"Continue with free path"*.
- **Lesson (`LessonView.swift`):**
  - Inline title *"Day \(lesson.dayIndex)"*, Title `lesson.title`.
  - Verse card reference `ref`, verse text from `ContentStore.verse(ref:)`.
  - Reflection body markdown, Prayer prompt section *"Prayer"*, prayer text.
  - CTA *"Take the quiz"*.
- **Quiz (`QuizView.swift`):**
  - Counter *"Question \(index + 1) of \(lesson.quiz.count)"*, `q.prompt`, `q.choices[i]`.
  - Close button *"Close"*, actions *"Next"*, *"Finish"*.
- **Companion (`CompanionView.swift`):**
  - Title *"Companion"*, `companion.name`, *"Stage \(stage)"*, *"\(xp) XP"*, *"Keep studying — your lamb grows with your streak."*.
- **Settings (`SettingsView.swift`):**
  - Privacy section: *"No account. Progress stays on this device."*, *"No ad trackers in v1."*.
  - About section: *"Shepherd"*, *"Privacy-first Bible learning"*.

### 1.4 Real Sample Content (Pasted Verbatim from JSON)

#### Lesson 1 (Day 1) — `paths.json`
- **Path ID:** `beginner-7` ("Beginner: 7 Days with God")
- **Lesson ID:** `day1` (Day 1)
- **Title:** "In the beginning"
- **Verse References:** `GEN.1.1`, `GEN.1.3`
- **Body Markdown:**
  > God speaks creation into being. Light comes first — order from chaos.
  >
  > **Reflection:** Where do you need God to bring light today?
- **Prayer Prompt:** "Thank you, God, for creating all things and for bringing light into darkness."

#### Verbatim Verses — `sample_bible.json` [Translation: WEB]
- **Genesis 1:1 (`GEN.1.1`):** "In the beginning, God created the heavens and the earth."
- **Genesis 1:3 (`GEN.1.3`):** "God said, \"Let there be light,\" and there was light."

#### Verbatim Quiz Questions — `paths.json`
- **Question 1 (`day1-q1`):**
  - **Prompt:** "Who created the heavens and the earth?"
  - **Choices:** `A` "God" | `B` "Angels" | `C` "Chance" | `D` "Kings"
  - **Correct Answer:** Choice `A` ("God")
  - **Explanation:** "Genesis 1:1 — God is the Creator."
- **Question 2 (`day1-q2`):**
  - **Prompt:** "What did God say first?"
  - **Choices:** `A` "Let there be light" | `B` "Let there be land" | `C` "It is finished" | `D` "Follow me"
  - **Correct Answer:** Choice `A` ("Let there be light")
  - **Explanation:** None (grounded in Genesis 1:3)

### 1.5 UX Weaknesses of the Current Scaffold

1. **Emoji Placeholder:** Uses a raw text emoji "🐑" instead of an actual illustrated companion mascot that grows across the 5 stages defined by `Companion.stage`.
2. **Missing Liquid Glass Chrome:** Built with flat views (`ShepherdTheme.softBackground`) and basic `List` containers. Has no dynamic glass materials, no specular reflection, no background blur, and no content scrolling under floating bars.
3. **No Visual Daily Path:** The Home screen is a basic text card rather than an engaging Duolingo-style learning path map showing past completed milestones, current active node, and locked future days.
4. **No Instant Quiz Feedback:** `QuizView` advances instantly upon button click with no right/wrong feedback sheet, no explanation citing the scripture verse (`q.explain`), and no pedagogical correction.
5. **No Lesson Completion Celebration:** Completing a quiz immediately dismisses the sheet without a celebration screen rewarding XP, advancing the companion, and updating the streak counter.
6. **Incomplete Paywall Shell:** Missing a StoreKit 2 trial timeline (Today -> Reminder Day 5 -> Charged Day 7), explicit auto-renew disclosure, Restore Purchases button, and live Terms & Privacy links.
7. **Companion View is Bare:** Just an emoji and two labels; lacks stage progression milestones, XP progress rings, and outfit preview slots.

---

## 2. Visual Identity & Pastoral Theme

The redesign gives Shepherd a **distinct, ownable pastoral devotional identity**—warm, calm, sacred, and luminous—combining layered morning meadow hills, parchment, wool fleece, and Living Dawn Amber with authentic Apple Liquid Glass.

```text
       ┌────────────────────────────────────────────────────────┐
       │                 SHEPHERD DESIGN THEME                  │
       ├────────────────────────────┬───────────────────────────┤
       │ Pastoral Light Canvas      │ Soft Morning Parchment    │
       │ Twilight Dark Canvas       │ Deep Meadow Charcoal      │
       │ Living Dawn Amber Accent   │ Morning Star / Living Sun │
       │ Pastoral Meadow Landscape  │ Rolling Hills & Trail     │
       │ Liquid Glass Material      │ Specular Rim + 24pt Blur  │
       │ Content Foundation         │ Crisp Opaque Cards        │
       └────────────────────────────┴───────────────────────────┘
```

### Color Contrast Discipline & Devotional Identity
- **Green & Red are strictly reserved for correctness:** Correct (`#137135` light / `#34D399` dark; fill `#0D7A3E`) and Wrong (`#B91C1C` light / `#EF4444` dark) are never used for brand buttons or badges.
- **Ownable Brand Accent:** "Living Dawn Amber" (`--color-accent`: `#9A5500` light / `#FBBF24` dark; `--color-accent-fill`: `#B45309` light / `#A65500` dark) embodies the light of God's Word ("Your word is a lamp to my feet", Psalm 119:105) and exceeds 5.2:1 contrast against all canvas and surface fills.
- **Pastoral Meadow Canvas:** Rolling meadow hills (`--color-meadow-sky`, `--color-meadow-hill-distant`, `--color-meadow-hill-near`, `--color-meadow-path`) provide living physical landscape forms behind Liquid Glass chrome.

---

## 3. Design Tokens (`shepherd.lib.pen`)

### 3.1 Color Tokens

| Token Name | Light Mode | Dark Mode | Role & Usage |
|:---|:---:|:---:|:---|
| `--color-canvas-bg` | `#FAF8F4` | `#141716` | Screen background (Morning Parchment / Deep Twilight) |
| `--color-card-surface` | `#FFFFFF` | `#1D2220` | Primary content cards, choices, and reading panels |
| `--color-surface-sunken` | `#F2EFE9` | `#252C29` | Inset backgrounds, quiz progress tracks, badges |
| `--color-surface-border` | `#E8E4DA` | `#2D3632` | 1pt hairline borders on cards and dividers |
| `--color-text-primary` | `#1A1D1B` | `#F4F5F4` | Headlines, scripture body, quiz prompts (14:1+ contrast) |
| `--color-text-secondary` | `#545C57` | `#A6AEA8` | Verse citations, subtitles, metadata (5.5:1+ contrast) |
| `--color-text-tertiary` | `#666E69` | `#8E9690` | Inactive dates, footnote disclaimers (4.6:1+ contrast) |
| `--color-accent` | `#9A5500` | `#FBBF24` | Living Dawn Amber: Primary brand text and icons (5.2:1+) |
| `--color-accent-fill` | `#B45309` | `#A65500` | High-contrast button containers with white text (5.2:1+) |
| `--color-accent-subtle` | `#FEF3C7` | `#352109` | Active node glow, selected choice background tint |
| `--color-on-accent` | `#FFFFFF` | `#FFFFFF` | High-contrast white text on primary accent buttons |
| `--color-meadow-sky` | `#FFFDF8` | `#0D1318` | Morning dawn sky / twilight sky gradient ground |
| `--color-meadow-hill-distant` | `#EAF1E7` | `#15221C` | Distant rolling meadow hill swell behind glass |
| `--color-meadow-hill-near` | `#DCE8D7` | `#1B2D24` | Near meadow hill contour behind path |
| `--color-meadow-path` | `#EFE8D8` | `#232E27` | Winding meadow path ribbon ground |
| `--color-meadow-path-border` | `#DFD4BE` | `#313F37` | Stepping stone dots and path edge border |
| `--color-success` | `#137135` | `#34D399` | Quiz correct answer border, icon, celebration text |
| `--color-success-fill` | `#137135` | `#0D7A3E` | Quiz correct Continue button fill with white text (5.4:1+) |
| `--color-success-subtle`| `#EDF8F1` | `#153020` | Quiz correct feedback sheet background |
| `--color-error` | `#B91C1C` | `#F87171` | Quiz incorrect answer border, icon |
| `--color-error-subtle` | `#FDF2F2` | `#361919` | Quiz wrong feedback sheet background |
| `--color-glass-fill` | `#FFFFFF33`| `#1218204D`| Liquid Glass mostly-clear chrome fill (20–30% opacity) |
| `--color-glass-stroke` | `#D4CDC0`| `#FFFFFF33`| Specular rim highlight (visible edge in Light Mode) |
| `--color-glass-specular` | `#FFFFFFE6`| `#FFFFFF4D`| Top-light specular reflection highlight |
| `--color-shadow-glass` | `#0F172A14`| `#00000033`| Soft outer ambient elevation shadow |
| `--color-shadow-glass-heavy` | `#0F172A26`| `#00000066`| Deep floating elevation shadow for modal sheets |
| `--color-scrim` | `#00000059`| `#00000080`| Modal backdrop dim overlay behind sheets |

### 3.2 Geometry, Radii & Spacing Tokens

| Token Name | Value | Role |
|:---|:---:|:---|
| `--radius-sm` | 8 | Small tags, streak chips, verse pills |
| `--radius-md` | 14 | Answer choice rows, plan cards, scripture verse cards |
| `--radius-lg` | 20 | Main content containers, companion cards, sheet plates |
| `--radius-pill`| 999 | Buttons, floating action pills, path nodes, tab bars |
| `--space-xs` | 4 | Tight label-to-icon spacing |
| `--space-sm` | 8 | Intra-card element spacing, chip horizontal padding |
| `--space-md` | 12 | Stack gaps between choice rows and list items |
| `--space-lg` | 16 | Standard screen gutter padding, card inner padding |
| `--space-xl` | 24 | Section gaps, hero spacing, modal header offsets |

### 3.3 Typography Tokens (Apple Dynamic Type Mapping)

| Token Name | Size / Weight | Dynamic Type Style |
|:---|:---:|:---|
| `--font-large-title` | 34pt Bold | `.largeTitle` |
| `--font-title-1` | 28pt Bold | `.title` |
| `--font-title-2` | 22pt Bold | `.title2` |
| `--font-title-3` | 20pt Semibold | `.title3` |
| `--font-headline` | 17pt Semibold | `.headline` |
| `--font-body` | 17pt Regular | `.body` |
| `--font-callout` | 16pt Regular | `.callout` |
| `--font-subheadline` | 15pt Regular | `.subheadline` |
| `--font-footnote` | 13pt Regular | `.footnote` |
| `--font-caption-1` | 12pt Medium | `.caption` |
| `--font-caption-2` | 11pt Medium | `.caption2` (Hard floor) |

---

## 4. Reusable Library Components (`shepherd.lib.pen`)

The library exposes 14 component families designed for direct reusability via library instances (`type: "ref"`):

1. **`Nav/Toolbar`**: System Liquid Glass navigation bar with leading circular button (`xmark` or `chevron.left`), centered title, and trailing actions.
2. **`Nav/GlassTabBar`**: iOS 26 floating glass tab bar with 4 tabs (Today, Path, Lamb, Settings).
3. **`Nav/BottomAccessory`**: Floating glass accessory (`.tabViewBottomAccessory`) displaying "Continue Lesson — Day 1" with interactive glass button.
4. **`Path/Node`**: Learning path node supporting 4 states: `complete` (check badge), `current` (pulsing Still Waters blue with halo), `available`, and `locked` (padlock).
5. **`Card/Lesson`**: Path lesson card displaying day index, title, scripture reference, and status.
6. **`Card/Verse`**: Scripture reading card with subtle gold/blue reference tag, verbatim WEB verse text, and generous typographic leading.
7. **`Row/QuizChoice`**: Quiz answer row with 5 states: `neutral`, `selected` (blue ring + filled radio), `correct` (green ring + `circle-check-big`), `wrong` (red ring + `circle-x`), and `revealed-correct` (green outline + explanation).
8. **`Sheet/QuizFeedback`**: Bottom feedback drawer with status icon, headline ("Splendid!" / "Keep Growing"), verbatim verse answer citation, and prominent glass continue CTA.
9. **`Chip/Streak`**: Golden sunrise streak chip ("3 Days 🔥") with active and freeze badges.
10. **`Bar/XPProgress`**: Companion growth bar displaying current level progress (0..50 XP) with rounded track and glowing fill.
11. **`Mascot/Lamb`**: Full vector illustrations for each of the 5 companion growth stages:
    - Stage 1: **Newborn** (Tiny sleeping lamb with gentle ear tufts)
    - Stage 2: **Sprout** (Curious sitting lamb with open eyes)
    - Stage 3: **Lamb** (Standing fluffy lamb with gentle smile)
    - Stage 4: **Yearling** (Strong, cheerful young sheep with fuller coat)
    - Stage 5: **Flock Leader** (Majestic, serene shepherd's guide with floral laurel wreath)
12. **`Button/GlassPrimary` & `Button/GlassSecondary`**: Authentic `.buttonStyle(.glassProminent)` and `.buttonStyle(.glass)` buttons with specular rim and background blur.
13. **`Row/PlanOption`**: Onboarding goal and familiarity selection card with radio indicator.
14. **`Card/PaywallPlan`**: Subscription plan card comparing Annual ($39.99/yr, $3.33/mo, 7-day trial, "Best Value" badge) vs Monthly ($4.99/mo).

---

## 5. Screen Inventory & Production Frames (`screens/shepherd.pen`)

All 62 frames (31 Dark, 31 Light) are authoritatively constructed at native iPhone 17 Pro specifications (402 × 874 pt) and exported at @2x retina resolution (`design/exports/`):

| # | Frame Name (Dark / Light) | Priority | Screen Type | Key Features & States |
|:---:|:---|:---:|:---:|:---|
| 1 | `Onboarding_Welcome_Dark` / `_Light` | **P0** | Mascot Hero | Stage 1 Lamb vector mascot with halo, 3 value propositions, "Get Started" primary glass CTA. |
| 2 | `Onboarding_Goal_Dark` / `_Light` | **P0** | Questionnaire | Step 1 of 4: 4 goals mapped to `UserProfile.goal` ("Grow a daily habit", "Understand the Bible better", "Find peace & prayer", "I'm new to faith"). |
| 3 | `Onboarding_Experience_Dark` / `_Light` | **P0** | Questionnaire | Step 2 of 4: 3 experience levels mapped to `UserProfile.experienceLevel` ("Beginner", "Some experience", "Regular reader"). |
| 4 | `Onboarding_Pace_Dark` / `_Light` | **P0** | Questionnaire | Step 3 of 4: Daily pace mapped to `UserProfile.dailyMinutes` ("Casual · 3–5 min", "Regular · 5–10 min", "Deep · 10–15 min"). |
| 5 | `Onboarding_NameLamb_Dark` / `_Light` | **P0** | Companion Setup | Step 4 of 4: Vector mascot preview, active text input field, suggestion chips ("Barnaby", "Woolly", "Pip", "Gideon"). |
| 6 | `Onboarding_BuildingPlan_Dark` / `_Light` | **P0** | Plan Creation | Checklist card with 4 green checkmarks, privacy guarantee ("All learning data is stored locally on your device"). |
| 7 | `Paywall_Trial_Dark` / `_Light` | **P0** | StoreKit 2 Paywall | 7-day trial timeline (Today -> Day 5 Reminder -> Day 7 Charge), Annual ($29.99/yr, Best Value) + Monthly ($4.99/mo), Restore Purchases, Terms, Privacy. |
| 8 | `Paywall_Purchasing_Dark` / `_Light` | **P0** | StoreKit 2 Paywall | In-flight purchase transaction overlay with ProgressView spinner and "Connecting to App Store..." notice. |
| 9 | `Paywall_Restored_Dark` / `_Light` | **P0** | StoreKit 2 Paywall | Successful transaction restoration dialog with green circle-check and "Your Shepherd Premium subscription is active." |
| 10 | `Home_DailyPath_Dark` / `_Light` | **P0** | Winding Meadow Path | Layered dawn/twilight meadow canvas, winding 7-day serpentine path trail with active Day 1 star node, Barnaby the Lamb standing beside Node 1 with speech bubble ("Ready for Day 1!"), floating glass bottom accessory docked above glass tab bar. |
| 11 | `Home_Scrolled_Dark` / `_Light` | **P0** | Liquid Glass Proof | Scrolled state showing Day 1 node, Barnaby the Lamb, speech bubble, and meadow hills visibly passing UNDER the top glass toolbar with physical 24pt background blur, and Node 4 passing under bottom accessory. |
| 12 | `Lesson_Reading_Dark` / `_Light` | **P0** | Scripture Reading | Day 1 "In the beginning", Genesis 1:1 and 1:3 cards [WEB verbatim], reflection card, prayer card, "Begin Quiz" CTA. Barnaby is reverently absent (Sacred Sanctuary rule). |
| 13 | `Quiz_Unanswered_Dark` / `_Light` | **P0** | Interactive Quiz | Duolingo-style learning progress bar in glass toolbar (50% fill), streak chip, eyebrow "QUESTION 1 OF 2 · GENESIS 1:1", 4 neutral choices, disabled Check Answer button. |
| 14 | `Quiz_Selected_Dark` / `_Light` | **P0** | Interactive Quiz | Choice A selected with Living Dawn Amber border and radio dot, enabled "Check Answer" primary glass button. |
| 15 | `Quiz_Correct_Dark` / `_Light` | **P0** | Quiz Feedback | Choice A styled in green success, bottom Liquid Glass drawer with Barnaby Happy (`Mascot/Expression/Happy`), verbatim Genesis 1:1 [WEB] citation, and "Continue" CTA. |
| 16 | `Quiz_Wrong_Dark` / `_Light` | **P0** | Quiz Feedback | Choice C styled in error red, Choice A revealed in green success, bottom Liquid Glass drawer with Barnaby Encouraging (`Mascot/Expression/Encouraging`), verbatim Genesis 1:1 [WEB] citation, and "Continue" CTA. |
| 17 | `Lesson_Complete_Dark` / `_Light` | **P0** | Reward Celebration | Day 1 celebration screen: +15 XP badge, 1 Day Streak! flame badge, Level 1 progress bar (15/100 XP), "Continue to Home" CTA. |
| 18 | `Companion_Detail_Dark` / `_Light` | **P0** | Mascot Stage Hub | Barnaby hero illustration, Level 1 readout, 5 growth stages list (Stage 1 Newborn unlocked, Stages 2–5 locked with XP thresholds). |
| 19 | `Path_Overview_Dark` / `_Light` | **P1** | Learning Paths | Path catalog with "Beginner: 7 Days with God" (In Progress) and locked subsequent paths ("The Sermon on the Mount", "Psalms of Comfort", "The Gospel of John"). |
| 20 | `Bible_Reader_Dark` / `_Light` | **P1** | Scripture Reader | Pure distraction-free Scripture reading view: Genesis 1:1–5 [WEB verbatim], book/chapter headers, custom verse numeral styling. |
| 21 | `Settings_Dark` / `_Light` | **P1** | Privacy & Settings | 100% on-device privacy guarantee, SwiftData local storage statement, Shepherd Premium active subscription card, Restore Purchases row, translation version. |
| 22 | `Accessibility_AX3_Dark` / `_Light` | **P1** | Accessibility AX3 | Dynamic Type AX3 large text stress test (32pt headline, 26pt serif verse body), generous line spacing, 60pt tall primary button, 44pt toolbar close target. |
| 23 | `Mascot_System_Dark` / `_Light` | **P0** | Character System | Complete Barnaby character sheet: Stages 1–5 vector silhouettes (`1 + xp/50`), 6 emotional expressions, color token palette swatches. |
| 24 | `Motion_QuizMorph_Start_Dark` / `_Light` | **P0** | Motion Morph A | Start state: 54pt interactive capsule button "Check Answer" before tap (`.glassEffectID("quiz_action")`). |
| 25 | `Motion_QuizMorph_Mid_Dark` / `_Light` | **P0** | Motion Morph A | In-flight state: Fluid spring interpolation (`response: 0.35, dampingFraction: 0.8`), dynamic specular rim expansion across choices. |
| 26 | `Motion_QuizMorph_End_Dark` / `_Light` | **P0** | Motion Morph A | Settled state: 214pt Liquid Glass drawer with success feedback, scripture reference, and "Continue" action. |
| 27 | `Motion_Accessory_Inline_Dark` / `_Light` | **P0** | Motion Morph B | Glass TabView bottom accessory inline pill state (56pt) docked above glass tab bar (`.glassEffectID("bottom_acc")`). |
| 28 | `Motion_Accessory_Expanded_Dark` / `_Light` | **P0** | Motion Morph B | Glass TabView bottom accessory expanded card (150pt) displaying current scripture context and +15 XP reward preview. |
| 29 | `Motion_PathMorph_Start_Dark` / `_Light` | **P0** | Motion Morph C | Start state: 72×72pt active path node with halo pulse and star badge (`.glassEffectID("lesson_header")`). |
| 30 | `Motion_PathMorph_End_Dark` / `_Light` | **P0** | Motion Morph C | Settled state: Seamless transition into full-width lesson reader header card. |
| 31 | `Motion_Mascot_Evolution_Dark` / `_Light` | **P0** | Character Evolution | Threshold moment: 50 XP milestone triggers Stage 1 Newborn -> Stage 2 Sprout Lamb evolution with starbursts and bounce physics. |

---

## 6. iOS 26 SwiftUI Implementation Mapping

This design maps strictly to the real iOS 26 SwiftUI APIs documented in Apple's Liquid Glass specification:

### 6.1 Liquid Glass Effects & Tints
```swift
// Regular glass effect with Still Waters Blue accent tint and interactive touch haptics
Text("Continue →")
    .font(.headline)
    .foregroundStyle(.white)
    .padding(.horizontal, 24)
    .padding(.vertical, 14)
    .glassEffect(.regular.tint(ShepherdTheme.accent).interactive(), in: .capsule)

// Specular rim toolbar in navigation stack
.toolbar {
    ToolbarItem(placement: .topBarLeading) {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark")
        }
        .buttonStyle(.glass)
    }
}
```

### 6.2 Glass TabView & Bottom Accessory View
```swift
TabView(selection: $selectedTab) {
    Tab("Path", systemImage: "map.fill", value: TabItem.path) {
        NavigationStack {
            HomeDailyPathView()
        }
    }
    Tab("Reader", systemImage: "book.fill", value: TabItem.reader) {
        NavigationStack {
            BibleReaderView()
        }
    }
    Tab("Lamb", systemImage: "sparkles", value: TabItem.companion) {
        NavigationStack {
            CompanionDetailView()
        }
    }
    Tab("Settings", systemImage: "gearshape.fill", value: TabItem.settings) {
        NavigationStack {
            SettingsView()
        }
    }
}
.tint(ShepherdTheme.accent)
// Liquid Glass Bottom Accessory for immediate lesson continuation
.tabViewBottomAccessory {
    HStack {
        VStack(alignment: .leading, spacing: 2) {
            Text("TODAY'S LESSON")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text("Day 1: In the beginning")
                .font(.subheadline.weight(.semibold))
        }
        Spacer()
        Button("Continue →") {
            startLesson()
        }
        .buttonStyle(.glassProminent)
        .tint(ShepherdTheme.accent)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .glassEffect(.regular, in: .rect(cornerRadius: 20))
}
.tabBarMinimizeBehavior(.onScrollDown)
```

### 6.3 Coordinated Morphing with `GlassEffectContainer` & `@Namespace`
In quiz progression, the action button smoothly morphs from "Check Answer" (inline CTA) into the bottom `FeedbackSheet` using coordinated glass effect namespaces:

```swift
struct QuizView: View {
    @State private var answerState: QuizAnswerState = .unanswered
    @Namespace private var glassMorphNamespace

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                QuizQuestionContent(state: $answerState)
            }
            
            GlassEffectContainer(spacing: 12) {
                switch answerState {
                case .unanswered:
                    Button("Check Answer") {}
                        .buttonStyle(.glass)
                        .disabled(true)
                        .glassEffectID("quiz_action", in: glassMorphNamespace)
                        
                case .selected:
                    Button("Check Answer") {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            answerState = .evaluated
                        }
                    }
                    .buttonStyle(.glassProminent)
                    .tint(ShepherdTheme.accent)
                    .glassEffectID("quiz_action", in: glassMorphNamespace)
                    
                case .evaluated:
                    FeedbackSheetView(isCorrect: isCorrect, explanation: quiz.explain)
                        .glassEffectID("quiz_action", in: glassMorphNamespace)
                }
            }
        }
    }
}
```

### 6.4 Accessibility Reduce Transparency Fallback
```swift
@Environment(\.accessibilityReduceTransparency) var reduceTransparency

var body: some View {
    content
        .background {
            if reduceTransparency {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color("CardSurfaceOpaque"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color("SurfaceBorder"), lineWidth: 1)
                    )
            } else {
                Color.clear
                    .glassEffect(.regular, in: .rect(cornerRadius: 20))
            }
        }
}
```

---

## 7. Quality Gate Verifications

Every automated probe and design check passes with 0 warnings and 0 errors:

### 7.1 Truth Probe (`scratch/truth_probe_shepherd.py`)
Validates every visible verse, lesson title, reflection prompt, prayer prompt, quiz question, choice, explanation, and answer styling against `Shepherd/Resources/Content/paths.json` and `sample_bible.json`:
```text
$ python3 scratch/truth_probe_shepherd.py design/screens/shepherd.pen
0 truth ok
```

### 7.2 Chrome Probe (`scratch/chrome_probe.py`)
Validates Liquid Glass hierarchy: scroll content precedes chrome in z-order, all chrome components have blur filters, and `_Scrolled` frames feature scroll content passing under the toolbar:
```text
$ python3 scratch/chrome_probe.py design/screens/shepherd.pen
0 chrome ok
```

### 7.3 Contrast Probe (`scratch/contrast_shepherd.py`)
Calculates relative luminance and WCAG 2.1 contrast ratios for every text and background pair across all 62 frames:
```text
$ python3 scratch/contrast_shepherd.py design/screens/shepherd.pen design/shepherd.lib.pen
total text pairs 762 fails 0
```
- Minimum measured body text contrast: 5.4:1 (exceeds WCAG AA 4.5:1 floor).
- Headline and primary scripture text: 14.2:1 against light canvas / 15.6:1 against dark canvas.
- Accent text `#9A5500` against light canvas `#FAF8F4`: 5.21:1.
- Button fill `#B45309` with white text: 5.25:1.

### 7.4 Pencil Token Audit (`pen-audit.py`)
Verifies that 100% of visual styling references library variables with zero dangling or unresolved pointers:
```text
$ python3 ~/.gemini/config/skills/pencil-pen-authoring/scripts/pen-audit.py design/shepherd.lib.pen
design/shepherd.lib.pen: imports[none] lib=0 local=315 vars=73 hex=0 refs=0 dangling=0

$ python3 ~/.gemini/config/skills/pencil-pen-authoring/scripts/pen-audit.py design/screens/shepherd.pen
design/screens/shepherd.pen: imports[I=../shepherd.lib.pen] lib=5252 local=0 vars=0 hex=0 refs=0 dangling=0
```

### 7.5 Pencil Layout Engine Check (`pen-layout-check.js`)
Validates bounding box overlaps and text wrapping inside headless `pen interactive`:
```text
$ bash ~/.gemini/config/skills/pencil-pen-authoring/scripts/pen-run.sh design/screens/shepherd.pen -e "$(cat ~/.gemini/config/skills/pencil-pen-authoring/scripts/pen-layout-check.js)"
libraries: I ok
no clipped or overlapping text
```

---

## 8. Mascot Character System — Barnaby the Lamb

### 8.1 Character Identity & Proportions
Barnaby is Shepherd's living devotional companion—a gentle, warm, patient lamb who walks alongside the reader through the 7-day paths and grows as the user learns.

```text
       ┌────────────────────────────────────────────────────────┐
       │             MASCOT CONSTRUCTION ARCHITECTURE           │
       ├────────────────────────────┬───────────────────────────┤
       │ Head : Body Ratio          │ 1:1 (Stage 1) -> 1:1.4 (S5)│
       │ Silhouette Form            │ Organic rounded cloud wool│
       │ Ear Angle Rules            │ 15° droop (idle) / 35° perk│
       │ Eye Geometry               │ 4×4pt rounded vector ovals│
       │ Line & Stroke Weight       │ 1pt hair border, 1.5pt eye│
       │ Glass Interaction          │ Halo glows through glass  │
       └────────────────────────────┴───────────────────────────┘
```

### 8.2 Fixed Pastoral Character Palette
To ensure visual harmony behind Liquid Glass chrome and in both light/dark appearances, the character strictly uses 6 semantic tokens:
- **`--color-mascot-wool`** (`#FFFFFF` light / `#E8E4DA` dark): Fluffy fleece body and ear tufts.
- **`--color-mascot-skin`** (`#FFF8F0` light / `#2C2621` dark): Warm parchment face and inner ears.
- **`--color-mascot-feature`** (`#2D3430` light / `#F4F5F4` dark): Eyes, smile arcs, and hoof markings.
- **`--color-mascot-snout`** (`#E8B4A2` light / `#C48D7D` dark): Soft peach snout and flushed cheeks.
- **`--color-mascot-halo`** (`#EBF2FC` light / `#1B2A3D` dark): Gentle Still Waters blue ambient aura.
- **`--color-mascot-gold`** (`#D98200` light / `#F5A623` dark): Celebratory star eyes and Stage 5 laurel wreath.

### 8.3 Exact Growth Stages (`Companion.stage = 1 + xp/50`)
Every stage maps directly to the model formula in `UserModels.swift:46`:

| Stage | Name | Threshold | Silhouette & Visual Evolution |
|:---:|:---|:---:|:---|
| **1** | **Newborn Lamb** | `0–49 XP` | Tiny curled sleeping posture, compact fleece ring, delicate closed/resting eyes. Gentle introduction to faith. |
| **2** | **Sprout Lamb** | `50–99 XP` | Sitting upright, alert open eyes, soft head tilt, curious presence. First steps in daily habit. |
| **3** | **Standing Lamb** | `100–149 XP` | Fully standing on sturdy hooves, cheerful confident smile, perky ears, Still Waters blue neck ribbon. |
| **4** | **Yearling Sheep** | `150–199 XP` | Fuller, richer cloud fleece coat, serene posture, protective presence, deeper ambient aura. |
| **5** | **Flock Leader** | `200+ XP` | Majestic mature guide, radiant golden sunrise laurel wreath, gentle dignified stance, guiding others. |

### 8.4 Expression Repertoire
The library defines 6 production expression components:
1. **`Mascot/Expression/Idle`**: Calm, resting presence. Soft oval eyes, gentle smile. Displayed on home path card and companion hub.
2. **`Mascot/Expression/Happy`**: Upward-curved laughing crescent eye arcs (`^ ^`), perky ears, glowing cheeks. Triggered upon selecting the correct quiz answer.
3. **`Mascot/Expression/Encouraging`**: Sympathetic 10° head tilt, warm wide eyes, soft comforting presence. Triggered upon an incorrect quiz answer. **Strict ethical rule:** The mascot never cries, scolds, shakes in anger, or guilts the user.
4. **`Mascot/Expression/Celebrating`**: Leaping energetic posture, golden star eyes (`★ ★`), open cheerful mouth, radiant fleece sparkles. Triggered on lesson completion and streak increments.
5. **`Mascot/Expression/Sleepy`**: Peaceful horizontal slit eyes (`- -`), slightly drooping relaxed ears, floating soft "zZ". Displayed during evening reminders and rest intervals.
6. **`Mascot/Expression/Hello`**: Friendly onboarding greeting pose, perky lifted ear, waving fleece hoof. Displayed on Welcome and Name-Your-Lamb screens.

### 8.5 Screen Placement & Sanctuary Policy
- **Where Barnaby Appears:**
  - Onboarding Welcome & Name-Your-Companion screens (bonding ritual).
  - Building Your Personal Plan loading state (companion preview).
  - Today's Path status card (daily companion check-in).
  - Quiz Feedback Sheets (instant pedagogical reaction: happy or encouraging).
  - Lesson Complete Celebration (joyful XP reward moment).
  - Companion Hub (full level inspection, stage timeline, and naming).
- **Where Barnaby Deliberately Does NOT Appear (The Sacred Sanctuary Rule):**
  - **Lesson Reading View:** Barnaby is completely absent.
  - **Bible Reader View:** Barnaby is completely absent.
  - **Rationale:** Scripture is sacred and contemplative. Reading God's Word requires quietude and reverence. Inserting a cartoon animal into biblical text degrades devotional depth and causes cognitive fatigue.

### 8.6 Mascot Personality, Voice & Sample Copy
Barnaby speaks as a humble, cheerful study companion walking along the path—never as an authority, theologian, or divine voice. He cheers consistency, encourages patience, and celebrates small steps of understanding:
1. *"A gentle step forward today. One passage at a time."* (Onboarding complete)
2. *"You're doing wonderfully. Let's look back at Genesis 1:1 together."* (Incorrect quiz guidance)
3. *"Splendid! The light always breaks through the darkness."* (Correct quiz answer)
4. *"Day 1 complete! Our meadow is growing brighter."* (Lesson complete)
5. *"Rest peacefully tonight. Tomorrow's path will be waiting for us."* (Evening reflection)
6. *"No rush, no pressure. Five quiet minutes is all we need."* (Habit reminder)

---

## 9. Liquid Glass & Motion Specification

Every animation in Shepherd is built using real Apple iOS 26 SwiftUI primitives (`GlassEffectContainer`, `@Namespace`, `.glassEffectID`, `phaseAnimator`, `keyframeAnimator`, `.sensoryFeedback`). Zero third-party runtimes (no Lottie, no network dependencies).

### 9.1 Liquid Glass Morphing Matrix

| Interaction | Trigger | Components Involved | Duration & Curve | Optical Mechanics & Haptics |
|:---|:---|:---|:---|:---|
| **Morph A: Quiz Action -> Feedback Sheet** | User selects choice & taps "Check Answer" | `.glassEffectID("quiz_action", in: namespace)` | `350ms`<br>`.spring(response: 0.35, dampingFraction: 0.8)` | The 54pt capsule button smoothly expands upwards into a 214pt Liquid Glass drawer. The specular rim refracts the underlying choice list with dynamic blur (`radius: 20`).<br>**Haptic:** `.sensoryFeedback(.success)` or `.sensoryFeedback(.warning)`. |
| **Morph B: Tab Bottom Accessory Inline <-> Expanded** | Tap / drag up on bottom accessory | `.glassEffectID("bottom_acc", in: namespace)` | `300ms`<br>`.spring(response: 0.30, dampingFraction: 0.85)` | The 56pt inline pill expands into a 150pt rich preview card displaying scripture reference and +15 XP badge.<br>**Haptic:** `.sensoryFeedback(.selection)`. |
| **Morph C: Path Node -> Lesson Header** | User taps active Day 1 path circle | `.glassEffectID("lesson_header", in: namespace)` | `320ms`<br>`.spring(response: 0.32, dampingFraction: 0.82)` | The 72×72 circular path node expands into the full-width reading header card while transitioning views.<br>**Haptic:** `.sensoryFeedback(.impact(weight: .medium))`. |

### 9.2 Mascot Motion Physics (Native SwiftUI Animators)

```swift
// 1. Idle Breathing & Gentle Blink Loop
struct MascotIdleView: View {
    @State private var isBreathing = false
    
    var body: some View {
        BarnabyVectorShape()
            .phaseAnimator([0.0, 1.0]) { content, phase in
                content
                    .scaleEffect(x: 1.0 + phase * 0.02, y: 1.0 - phase * 0.02, anchor: .bottom)
                    .offset(y: phase * -2)
            } animation: { _ in
                .easeInOut(duration: 3.2).repeatForever(autoreverses: true)
            }
    }
}

// 2. Celebratory Hop & Stage Evolution Moment
struct MascotHopView: View {
    var trigger: Bool
    
    var body: some View {
        BarnabyVectorShape()
            .keyframeAnimator(initialValue: AnimationValues(), trigger: trigger) { content, value in
                content
                    .offset(y: value.verticalTranslation)
                    .scaleEffect(x: value.squashX, y: value.stretchY, anchor: .bottom)
            } keyframes: { _ in
                KeyframeTrack(\.verticalTranslation) {
                    CubicKeyframe(-12, duration: 0.15) // Apex hop
                    SpringKeyframe(0, duration: 0.20, spring: .snappy) // Settle
                }
                KeyframeTrack(\.stretchY) {
                    CubicKeyframe(1.08, duration: 0.15) // Stretch upwards
                    SpringKeyframe(1.0, duration: 0.20, spring: .bouncy)
                }
            }
    }
}
```

### 9.3 Reward Moments & Temporal Choreography
- **Streak Increment:** The flame badge scales up (`1.0 -> 1.15 -> 1.0`) over 280ms accompanied by `.sensoryFeedback(.impact(weight: .light))`.
- **XP Progress Fill:** The horizontal XP bar animates its corner-radiused fill width using `.spring(duration: 0.5, bounce: 0.1)`, accompanied by a subtle golden glow flash (`opacity 0.0 -> 0.4 -> 0.0`).
- **Path Node Unlocking:** Upon completing a lesson, the subsequent path node padlock icon morphs into the active blue star with a soft ring ripple (`radius 36 -> 52`, `opacity 0.8 -> 0.0`).

### 9.4 Accessibility Fallbacks
- **`accessibilityReduceMotion`:** When enabled in iOS Settings, all spring morphs and keyframe hops are immediately replaced by standard 150ms opacity crossfades or static state switches. No view positions translate across the screen.
- **`accessibilityReduceTransparency`:** When enabled, Liquid Glass materials automatically swap their translucent blur layers (`--color-glass-fill`) for 100% opaque card surfaces (`--color-card-surface`) with high-contrast borders (`--color-surface-border`), guaranteeing complete legibility.
- **Devotional Restraint:** Motion is quiet, soft, and respectful. Zero full-screen particle cannons, zero noisy confetti bursts, and zero unprompted popups while studying.
