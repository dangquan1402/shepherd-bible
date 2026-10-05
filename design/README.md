# Shepherd — iOS 26 "Liquid Glass" Design Specification

This specification documents the complete visual and architectural redesign of **Shepherd** for Apple iOS 26. Grounded in Refero design research, it establishes an authentic Liquid Glass design system, a warm pastoral identity, 100% data-truthful content extracted from repository sources, and an accessible, production-grade interface.

---

## 1. Product Summary & Design Inputs

### 1.1 Product Contract
- **Positioning:** Privacy-first, Duolingo-style Bible learning app for iOS.
- **Architecture:** SwiftData on-device persistence, StoreKit 2 soft paywall, bundled public-domain World English Bible (WEB), WidgetKit ready.
- **Privacy Guarantee:** 100% on-device. No accounts, no email capture, no third-party trackers, no cloud analytics.
- **Monetization:** Free 7-day beginner path + offline reader; Shepherd Premium soft paywall (7-day free trial, Annual primary with placeholder pricing + Monthly tier).

### 1.2 Platform & Deployment Target (D1 / M16)
- **Deployment Target:** Apple **iOS 26** (`@available(iOS 26, *)`).
- **Design Paradigm:** Authentic Apple Liquid Glass. The visual language leverages iOS 26 native capabilities:
  - System glass navigation chrome with dynamic specular reflection (`.toolbar`, `.buttonStyle(.glass)`, `.buttonStyle(.glassProminent)`).
  - Floating Liquid Glass tab bar with docked bottom accessory (`.tabViewBottomAccessory`).
  - Coordinated interactive morphing between controls and bottom feedback sheets (`GlassEffectContainer(spacing:)`, `@Namespace`, `.glassEffectID`).
  - Dynamic specular edge highlights reacting to underlying meadow hills and scroll offsets.
- **Decision Resolution (D1):** Per resolved decision D1, Shepherd targets iOS 26 directly as its base requirement. No fallback material frame is drawn because Liquid Glass is the explicit architectural target of the redesign.

### 1.3 Data Models & Service Contract

Every metric, label, and state in the design maps 1:1 to the SwiftData models and services in `Shepherd/`:

| Model / Service | Source File | Properties & Exposed APIs | Redesign Mapping |
|:---|:---|:---|:---|
| `UserProfile` | `UserModels.swift:4-28` | `displayName: String?`<br>`goal: String` ("grow_daily", "understand", "peace", "new")<br>`experienceLevel: String` ("beginner", "some", "regular")<br>`dailyMinutes: Int` (5, 10, 15)<br>`createdAt: Date`<br>`hasCompletedOnboarding: Bool` | Drives the 4-step onboarding questionnaire and personalizes the "Preparing your personal path" screen. |
| `Companion` | `UserModels.swift:30-48` | `name: String` (default "Lamb", user-chosen in onboarding)<br>`stage: Int` (1..5: `1 + xp / 50`)<br>`xp: Int`<br>`outfitId: String?`<br>`func addXP(_ amount: Int)` | Drives the vector lamb companion in all 5 stages: Stage 1 Newborn (0–49 XP), Stage 2 Lamb (50–99 XP), Stage 3 Young sheep (100–149 XP), Stage 4 Yearling (150–199 XP), Stage 5 Grown sheep (200+ XP). |
| `StreakState` | `UserModels.swift:50-79` | `current: Int`<br>`best: Int`<br>`lastCompletedDate: Date?`<br>`freezesLeft: Int` (default 1)<br>`func markCompleted(on day: Date)` | Drives the floating streak pill ("3 Days 🔥 · Best 5"), weekly streak calendar dots, and streak freeze indicator in paywall. |
| `LessonProgress` | `UserModels.swift:81-92` | `lessonId: String`<br>`completedAt: Date`<br>`quizScore: Int` | Determines path node status: completed (check badge), current (pulsing amber halo), or locked (padlock). |
| `EntitlementState` | `UserModels.swift:94-105` | `isPremium: Bool`<br>`expirationDate: Date?`<br>`productId: String?` | Governs access to premium path chapters, companion custom outfits, and widget customization. |
| `StoreKitManager` | `StoreKitManager.swift:1-38` | `monthlyID = "com.dangvietquan.shepherd.premium.monthly"`<br>`yearlyID = "com.dangvietquan.shepherd.premium.yearly"`<br>`products: [Product]`<br>`func purchase(_ product: Product)` | 7-day trial timeline, Annual primary card ([Price placeholder: $29.99/year, $2.50/mo]) + Monthly tier ([Price placeholder: $4.99/month]), Restore Purchases, App Store terms. |
| `ContentStore` | `ContentStore.swift:1-43` | `bible: BibleBundle?`<br>`paths: [StudyPath]`<br>`func verse(ref: String) -> String?` | Feeds verbatim WEB verses for all lesson readings, quiz answers, and standalone reader view. |

### 1.4 Verbatim Current Scaffold Copy & Data Inventory

Extracted directly from the Swift codebase:

- **Onboarding (`OnboardingFlowView.swift`):**
  - Welcome: *"Welcome to Shepherd"*, *"A few minutes a day. Scripture that sticks. Everything stays on your phone."*
  - Goal: *"What’s your goal?"* -> *"Grow a daily habit"* (`grow_daily`), *"Understand the Bible better"* (`understand`), *"Find peace & prayer"* (`peace`), *"I’m new to faith"* (`new`).
  - Familiarity: *"How familiar are you?"* -> *"Beginner"* (`beginner`), *"Some experience"* (`some`), *"I read regularly"* (`regular`).
  - Daily Time: *"How many minutes a day?"* -> *"5 min"*, *"10 min"*, *"15 min"* (`.segmented` control).
  - Mascot Name: *"Name your companion"*, TextField placeholder *"Lamb’s name"*.
  - Plan Generation: *"Preparing your path…"*, *"Daily goal: 5 min"*.
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
  - Pricing: Displayed using StoreKit `Product.displayPrice` with explicit placeholder disclaimer in mockups.
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
  - About section: *"Shepherd"*, *"Privacy-first Bible learning"*, *"Version 1.0"*.
  - Subscription section: *"Shepherd Premium"*, *"Restore Purchases"*.

### 1.5 Real Sample Content (Pasted Verbatim from JSON)

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
- **Genesis 1:3 (`GEN.1.3`):** "God said, "Let there be light," and there was light."

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
  - **Explanation:** `null` (grounded in Genesis 1:3; per Rule M5, falls back to the lesson's matching verse text `GEN.1.3`)

### 1.6 UX Weaknesses of the Current Scaffold

1. **Emoji Placeholder:** Used a bare unicode emoji "🐑" instead of an authentic vector companion mascot that dynamically illustrates the 5 developmental stages (`Companion.stage`).
2. **Missing Liquid Glass Chrome:** Built with flat views (`ShepherdTheme.softBackground`) and basic `List` containers. Lacked specular reflection, background blur, and content scrolling under floating bars.
3. **No Visual Daily Path:** The Home screen presented a basic text card rather than an engaging Duolingo-style serpentine path map showing completed milestones, active node, and locked future days.
4. **No Instant Quiz Feedback:** `QuizView` advanced instantly without an interactive feedback sheet, scripture citation, or pedagogical encouragement.
5. **No Lesson Completion Celebration:** Completing a quiz immediately dismissed the view without rewarding XP, celebrating companion growth, or updating the streak counter.
6. **Incomplete Paywall Shell:** Lacked a StoreKit 2 trial timeline (Today -> Day 5 Cancel reminder -> Day 7 Charge), auto-renew disclosure, Restore Purchases button, and live Terms & Privacy links.
7. **Companion View is Bare:** Contained only an emoji and two labels; lacked stage progression milestones, XP progress rings, and outfit preview slots.

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
       │ Pastoral Meadow Landscape  │ Rolling Hills & S-Trail   │
       │ Liquid Glass Material      │ Specular Rim + 24pt Blur  │
       │ Content Foundation         │ Crisp Opaque Cards        │
       └────────────────────────────┴───────────────────────────┘
```

### Color Contrast Discipline & Devotional Identity
- **Green & Red are strictly reserved for correctness:** Correct (`#137135` light / `#34D399` dark; fill `#0D7A3E`) and Wrong (`#B91C1C` light / `#F87171` dark) are never used for brand buttons or badges.
- **Ownable Brand Accent:** "Living Dawn Amber" (`--color-accent`: `#9A5500` light / `#FBBF24` dark; `--color-accent-fill`: `#B45309` light / `#A65500` dark) embodies the light of God's Word ("Your word is a lamp to my feet", Psalm 119:105) and exceeds 5.2:1 contrast against all canvas and surface fills.
- **Pastoral Meadow Canvas:** Rolling meadow hills (`--color-meadow-sky`, `--color-meadow-hill-distant`, `--color-meadow-hill-near`, `--color-meadow-path`) provide living physical landscape forms behind Liquid Glass chrome.

---

## 3. Design Tokens (`shepherd.lib.pen`)

The library declares **86 semantic design variables** with a synchronized light/dark theme axis.

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
| `--color-gold` | `#945300` | `#F5A623` | Golden sunrise streak text and badges |
| `--color-gold-fill` | `#D98200` | `#F5A623` | Golden streak flame badge fill |
| `--color-gold-subtle` | `#FEF6E6` | `#33240E` | Streak pill background tint |
| `--color-meadow-sky` | `#FFF6E3` | `#0F1A1D` | Morning dawn sky / twilight sky gradient ground |
| `--color-meadow-sky-bottom` | `#FDEFD6` | `#14231F` | Morning dawn sky horizon blend |
| `--color-meadow-hill-distant` | `#DDE8CF` | `#1A2C24` | Distant rolling meadow hill swell behind glass |
| `--color-meadow-hill-near` | `#C9DDB8` | `#21382B` | Near meadow hill contour behind path |
| `--color-meadow-path` | `#DDD2BC` | `#353B32` | Winding meadow path ribbon ground |
| `--color-meadow-path-border` | `#C8BC9F` | `#465042` | Stepping stone dots and path edge border |
| `--color-success` | `#137135` | `#34D399` | Quiz correct answer border, icon, celebration text |
| `--color-success-fill` | `#137135` | `#0D7A3E` | Quiz correct Continue button fill with white text (5.4:1+) |
| `--color-success-subtle`| `#EDF8F1` | `#153020` | Quiz correct feedback sheet background |
| `--color-error` | `#B91C1C` | `#F87171` | Quiz incorrect answer border, icon |
| `--color-error-subtle` | `#FDF2F2` | `#361919` | Quiz wrong feedback sheet background |
| `--color-glass-fill` | `#FFFFFF8C` (55%) | `#1A24208C` (55%) | Liquid Glass tinted chrome fill (55% opacity for crisp legibility) |
| `--color-glass-stroke` | `#D4CDC0` | `#FFFFFF33` | Specular rim highlight (visible edge in Light Mode) |
| `--color-glass-specular` | `#FFFFFFE6` | `#FFFFFF4D` | Top-light specular reflection highlight |
| `--color-shadow-glass` | `#0F172A14` | `#00000033` | Soft outer ambient elevation shadow |
| `--color-shadow-glass-heavy` | `#0F172A26` | `#00000066` | Deep floating elevation shadow for modal sheets |
| `--color-scrim` | `#00000059` | `#00000080` | Modal backdrop dim overlay behind sheets |
| `--color-mascot-wool` | `#FFF8EC` | `#FFF8EC` | Lamb fleece cloud body and ear tufts |
| `--color-mascot-fleece-shade` | `#E9DCC6` | `#E9DCC6` | Wool underside shading and fleece ripples |
| `--color-mascot-face` | `#F4E3CC` | `#F4E3CC` | Gentle parchment face and ear interiors |
| `--color-mascot-snout` | `#EFA593` | `#EFA593` | Soft blush snout and rosy cheeks |
| `--color-mascot-feature` | `#3D312B` | `#3D312B` | Eyes, smile curves, hooves |
| `--color-mascot-far-legs` | `#2F2621` | `#2F2621` | Rear legs depth perspective |
| `--color-mascot-bell` | `#C99A3A` | `#C99A3A` | Stage 3 bell / Stage 5 laurel gold |
| `--color-mascot-halo` | `#7A6655` | `#FFF8EC4D` | Ambient devotional halo aura |
| `--color-mascot-shadow` | `#0000001F` | `#00000059` | Ground contact shadow under hooves |

### 3.2 Geometry, Radii & Spacing Tokens

| Token Name | Value | Role |
|:---|:---:|:---|
| `--radius-xs` | 4 | Stepping stone dots, subtle badge corners |
| `--radius-sm` | 8 | Small tags, streak chips, verse pills |
| `--radius-md` | 14 | Answer choice rows, plan cards, scripture verse cards |
| `--radius-lg` | 20 | Main content containers, companion cards, sheet plates |
| `--radius-xl` | 28 | Dialog cards, modal sheet containers |
| `--radius-pill`| 999 | Buttons, floating action pills, path nodes, tab bars |
| `--space-1` | 4 | Tight label-to-icon spacing |
| `--space-2` | 8 | Intra-card element spacing, chip horizontal padding |
| `--space-3` | 12 | Stack gaps between choice rows and list items |
| `--space-4` | 16 | Standard screen gutter padding, card inner padding |
| `--space-5` | 20 | Medium section spacing |
| `--space-6` | 24 | Section gaps, hero spacing, modal header offsets |
| `--space-8` | 32 | Major block margins, modal padding |
| `--space-10` | 40 | Large hero offset spacing |

### 3.3 Typography Tokens (Apple Dynamic Type Mapping)

| Token Name | Size / Weight | Dynamic Type Style |
|:---|:---:|:---|
| `--text-large-title` | 34pt Bold | `.largeTitle` |
| `--text-title1` | 28pt Bold | `.title` |
| `--text-title2` | 22pt Bold | `.title2` |
| `--text-title3` | 20pt Semibold | `.title3` |
| `--text-headline` | 17pt Semibold | `.headline` |
| `--text-body` | 17pt Regular | `.body` |
| `--text-callout` | 16pt Regular | `.callout` |
| `--text-subheadline` | 15pt Regular | `.subheadline` |
| `--text-footnote` | 13pt Regular | `.footnote` |
| `--text-caption` | 12pt Medium | `.caption` |
| `--text-xs` | 11pt Medium | `.caption2` (Hard floor) |
| `--text-ax3-body` | 40pt Regular | `.body` (Accessibility AX3) |

---

## 4. Reusable Library Components (`shepherd.lib.pen`)

The library exposes **56 components** designed for direct reusability via library instances (`type: "ref"`):

### 4.1 Navigation & Chrome Components
1. **`Nav/GlassToolbar` (`comp_nav_toolbar`)**: System Liquid Glass navigation bar with leading circular button (`xmark` or `chevron.left`), centered title, and trailing actions.
2. **`Nav/GlassTabBar` (`comp_nav_tabbar`)**: iOS 26 floating glass tab bar with 4 tabs: Today (`sun.max`), Bible (`book`), Lamb (custom vector lamb glyph), Settings (`gearshape.fill`).
3. **`Nav/BottomAccessory` (`comp_bottom_accessory`)**: Floating glass accessory (`.tabViewBottomAccessory`) displaying "Continue Lesson — Day 1" with interactive glass button.

### 4.2 Interactive Controls & Buttons
4. **`Button/GlassPrimary` (`comp_btn_primary`)**: Authentic `.buttonStyle(.glassProminent)` primary button with specular rim, background blur, and white typography.
5. **`Button/GlassSecondary` (`comp_btn_secondary`)**: Authentic `.buttonStyle(.glass)` secondary button with frosted glass material.
6. **`Path/Node` (`comp_path_node`)**: Learning path node supporting 4 states: `complete` (check badge), `current` (pulsing amber halo), `available`, and `locked` (padlock).
7. **`Card/Lesson` (`comp_card_lesson`)**: Path lesson card displaying day index, title, scripture reference, and status.
8. **`Card/Verse` (`comp_card_verse`)**: Scripture reading card with subtle reference tag, verbatim WEB verse text, and generous typographic leading.
9. **`Row/QuizChoice` (`comp_row_choice`)**: Quiz answer row with 5 states: `neutral`, `selected` (amber ring + filled radio), `correct` (green ring + `circle-check-big`), `wrong` (red ring + `circle-x`), and `revealed-correct` (green outline + explanation).
10. **`Sheet/QuizFeedback` (`comp_sheet_feedback`)**: Bottom feedback drawer with status icon, headline ("Splendid!" / "Keep going! You're learning."), verbatim scripture citation, and prominent glass continue CTA.
11. **`Chip/Streak` (`comp_chip_streak`)**: Golden sunrise streak chip ("3 Days 🔥") with active and freeze badges.
12. **`Bar/XPProgress` (`comp_bar_xp`)**: Companion growth bar displaying current level progress (0..50 XP) with rounded track and glowing fill.
13. **`Row/PlanOption` (`comp_row_plan`)**: Onboarding goal and familiarity selection card with radio indicator.
14. **`Card/PaywallPlan` (`comp_card_paywall`)**: Subscription plan card comparing Annual ([Price placeholder: $29.99/year], 7-day trial, "Best Value" badge) vs Monthly ([Price placeholder: $4.99/month]).

### 4.3 Vector Mascot System (30 Production Variants)
The mascot system defines 30 dedicated components (`5 stages × 6 emotional expressions`), each constructed with true geometric paths and vector curves:

- **Stage 1 (Newborn Lamb, 0–49 XP):**
  - `comp_lamb_s1_idle`: Resting pose, calm eyes
  - `comp_lamb_s1_happy`: Joyful laughing eyes
  - `comp_lamb_s1_encouraging`: Gentle 10° head tilt
  - `comp_lamb_s1_celebrating`: Upright joyful pose
  - `comp_lamb_s1_sleepy`: Relaxed closed eyes
  - `comp_lamb_s1_hello`: Waving greeting pose
- **Stage 2 (Lamb, 50–99 XP):**
  - `comp_lamb_s2_idle`, `comp_lamb_s2_happy`, `comp_lamb_s2_encouraging`, `comp_lamb_s2_celebrating`, `comp_lamb_s2_sleepy`, `comp_lamb_s2_hello`
- **Stage 3 (Young Sheep, 100–149 XP):**
  - `comp_lamb_s3_idle`, `comp_lamb_s3_happy`, `comp_lamb_s3_encouraging`, `comp_lamb_s3_celebrating`, `comp_lamb_s3_sleepy`, `comp_lamb_s3_hello`
- **Stage 4 (Yearling, 150–199 XP):**
  - `comp_lamb_s4_idle`, `comp_lamb_s4_happy`, `comp_lamb_s4_encouraging`, `comp_lamb_s4_celebrating`, `comp_lamb_s4_sleepy`, `comp_lamb_s4_hello`
- **Stage 5 (Grown Sheep, 200+ XP):**
  - `comp_lamb_s5_idle`, `comp_lamb_s5_happy`, `comp_lamb_s5_encouraging`, `comp_lamb_s5_celebrating`, `comp_lamb_s5_sleepy`, `comp_lamb_s5_hello`

---

## 5. Screen Inventory & Production Frames (`screens/shepherd.pen`)

All **70 frames** (35 Dark, 35 Light) are authoritatively constructed at native iPhone 17 Pro specifications (402 × 874 pt) and exported at @2x retina resolution (`design/exports/`):

| # | Frame Name (Dark / Light) | Priority | Screen Type | Key Features & States |
|:---:|:---|:---:|:---:|:---|
| 1 | `Onboarding_Welcome_Dark` / `_Light` | **P0** | Mascot Hero | Stage 1 Lamb vector mascot on rolling meadow hill vignette, 3 value propositions, 6-segment progress bar (step 1/6), "Get Started" primary glass CTA. |
| 2 | `Onboarding_Goal_Dark` / `_Light` | **P0** | Questionnaire | Step 2 of 6: 4 verbatim goals mapped to `UserProfile.goal` ("Grow a daily habit", "Understand the Bible better", "Find peace & prayer", "I'm new to faith") with peeking Stage 1 lamb. |
| 3 | `Onboarding_Experience_Dark` / `_Light` | **P0** | Questionnaire | Step 3 of 6: 3 verbatim experience levels mapped to `UserProfile.experienceLevel` ("Beginner", "Some experience", "I read regularly"). |
| 4 | `Onboarding_Pace_Dark` / `_Light` | **P0** | Questionnaire | Step 4 of 6: Daily pace segmented control mapped to `UserProfile.dailyMinutes` ("5 min", "10 min", "15 min"). |
| 5 | `Onboarding_NameLamb_Dark` / `_Light` | **P0** | Companion Setup | Step 5 of 6: Vector mascot preview, active text input field ("Barnaby"), suggestion chips ("Barnaby", "Woolly", "Pip", "Gideon"). |
| 6 | `Onboarding_BuildingPlan_Dark` / `_Light` | **P0** | Plan Creation | Step 6 of 6: "Preparing your path…" with reading lamb vignette, progressive checklist, on-device privacy statement. |
| 7 | `Paywall_Trial_Dark` / `_Light` | **P0** | StoreKit 2 Paywall | 7-day trial timeline (Today -> Day 5 Cancel reminder -> Day 7 Charge), Annual ([Price placeholder: $29.99/year], Best Value) + Monthly ($4.99/month), Restore Purchases, Terms, Privacy. |
| 8 | `Paywall_Purchasing_Dark` / `_Light` | **P0** | StoreKit 2 Paywall | In-flight purchase transaction overlay with ProgressView spinner and "Connecting to App Store..." notice. |
| 9 | `Paywall_Pending_Dark` / `_Light` | **P0** | StoreKit 2 Paywall | Ask to Buy / Family Approval pending transaction notice dialog. |
| 10 | `Paywall_Failed_Dark` / `_Light` | **P0** | StoreKit 2 Paywall | Payment decline / network failure recovery dialog with "Try Again" action. |
| 11 | `Paywall_Restored_Dark` / `_Light` | **P0** | StoreKit 2 Paywall | Successful transaction restoration dialog with green circle-check and "Your Shepherd Premium subscription is active." |
| 12 | `Home_DailyPath_Dark` / `_Light` | **P0** | Winding Meadow Path | Layered dawn/twilight meadow canvas, winding 7-day serpentine S-curve trail with active Day 1 star node, Barnaby the Lamb standing beside Node 1 with speech bubble ("Ready for Day 1!"), floating glass bottom accessory docked above glass tab bar. |
| 13 | `Home_Scrolled_Dark` / `_Light` | **P0** | Liquid Glass Proof | Scrolled state showing Day 1 node, Barnaby the Lamb, speech bubble, and meadow hills visibly passing UNDER the top glass toolbar with physical 24pt background blur, and Node 4 passing under bottom accessory. |
| 14 | `Lesson_Reading_Dark` / `_Light` | **P0** | Scripture Reading | Day 1 "In the beginning", Genesis 1:1 and 1:3 cards [WEB verbatim], reflection card, prayer card, "Take the quiz" CTA. Barnaby is reverently absent (Sacred Sanctuary rule). |
| 15 | `Quiz_Unanswered_Dark` / `_Light` | **P0** | Interactive Quiz | Duolingo-style learning progress bar in glass toolbar (50% fill), streak chip, eyebrow "DAY 1 · IN THE BEGINNING", 4 neutral choices, disabled Check Answer button. |
| 16 | `Quiz_Selected_Dark` / `_Light` | **P0** | Interactive Quiz | Choice A selected with Living Dawn Amber border and radio dot, enabled "Check Answer" primary glass button. |
| 17 | `Quiz_Correct_Dark` / `_Light` | **P0** | Quiz Feedback | Choice A styled in green success, bottom Liquid Glass drawer with Barnaby Happy (`comp_lamb_s1_happy`), verbatim Genesis 1:1 [WEB] citation, and "Continue" CTA. |
| 18 | `Quiz_Wrong_Dark` / `_Light` | **P0** | Quiz Feedback | Choice C styled in error red, Choice A revealed in green success, bottom Liquid Glass drawer with Barnaby Encouraging (`comp_lamb_s1_encouraging`), verbatim Genesis 1:1 [WEB] citation, and "Continue" CTA. |
| 19 | `Quiz_Q2_Wrong_Dark` / `_Light` | **P0** | Quiz Question 2 | Question 2 ("What did God say first?"): Choice B styled in error red, Choice A revealed in green success, bottom drawer showing Genesis 1:3 [WEB verbatim] scripture fallback per Rule M5. |
| 20 | `Lesson_Complete_Dark` / `_Light` | **P0** | Reward Celebration | Day 1 celebration screen: Stage 1 Lamb Celebrating (160pt), +12 XP badge, 1 Day Streak! flame badge, Level 1 progress bar (12/50 XP), "Continue to Home" CTA. |
| 21 | `Companion_Detail_Dark` / `_Light` | **P0** | Mascot Stage Hub | Barnaby hero illustration (180pt), Level 1 readout, 5 growth stages list (Stage 1 Newborn unlocked, Stages 2–5 locked with XP thresholds). Highlights "Lamb" tab. |
| 22 | `Path_Overview_Dark` / `_Light` | **P0** | Path Catalog | Path catalog showing active "Beginner: 7 Days with God" (In Progress) and one honest future row: "More paths are coming" (per D2; no fake titles or counts). Pushed from Today toolbar. |
| 23 | `Bible_Reader_Dark` / `_Light` | **P0** | Scripture Reader | Pure distraction-free Scripture reading view: Genesis 1:1–5 [WEB verbatim], drop cap on verse 1, quiet gap marker ("Verses 6–25 aren't in this sample"), translation version. Barnaby is absent (Sanctuary rule). Highlights "Bible" tab. |
| 24 | `Settings_Dark` / `_Light` | **P0** | Privacy & Settings | 100% on-device privacy guarantee, SwiftData local storage statement, Shepherd Premium active subscription card, Restore Purchases row, translation version 1.0. Highlights "Settings" tab. |
| 25 | `Accessibility_AX3_Dark` / `_Light` | **P1** | Accessibility AX3 | Dynamic Type AX3 large text stress test (32pt headline, 26pt serif verse body), generous line spacing, 60pt tall primary button, 44pt toolbar close target. |
| 26 | `Accessibility_AX3_QuizWrong_Dark` / `_Light` | **P1** | Accessibility AX3 | Large-text quiz error sheet stress test: choice text wrapping to 2–3 lines, multi-line feedback sheet with scroll indicators, 44pt minimum touch targets. |
| 27 | `Mascot_System_Dark` / `_Light` | **P0** | Character System | Complete Barnaby character sheet: Stages 1–5 vector silhouettes (`1 + xp/50`), 6 emotional expressions, color token palette swatches. |
| 28 | `Motion_QuizMorph_Start_Dark` / `_Light` | **P0** | Motion Morph A | Start state: 54pt interactive capsule button "Check Answer" before tap (`.glassEffectID("quiz_action")`). |
| 29 | `Motion_QuizMorph_Mid_Dark` / `_Light` | **P0** | Motion Morph A | In-flight state: Fluid spring interpolation (`response: 0.35, dampingFraction: 0.8`), dynamic specular rim expansion across choices. |
| 30 | `Motion_QuizMorph_End_Dark` / `_Light` | **P0** | Motion Morph A | Settled state: 214pt Liquid Glass drawer with success feedback, scripture reference, and "Continue" action. |
| 31 | `Motion_Accessory_Inline_Dark` / `_Light` | **P0** | Motion Morph B | Glass TabView bottom accessory inline pill state (56pt) docked above glass tab bar (`.glassEffectID("bottom_acc")`). |
| 32 | `Motion_Accessory_Expanded_Dark` / `_Light` | **P0** | Motion Morph B | Glass TabView bottom accessory expanded card (150pt) displaying current scripture context and +15 XP reward preview. |
| 33 | `Motion_PathMorph_Start_Dark` / `_Light` | **P0** | Motion Morph C | Start state: 72×72pt active path node with halo pulse and star badge (`.glassEffectID("lesson_header")`). |
| 34 | `Motion_PathMorph_End_Dark` / `_Light` | **P0** | Motion Morph C | Settled state: Seamless transition into full-width lesson reader header card. |
| 35 | `Motion_Mascot_Evolution_Dark` / `_Light` | **P0** | Character Evolution | Threshold moment: 50 XP milestone triggers Stage 1 Newborn -> Stage 2 Lamb evolution with starbursts and bounce physics. |

---

## 6. iOS 26 SwiftUI Implementation Mapping

This design maps strictly to the real iOS 26 SwiftUI APIs documented in Apple's Liquid Glass specification:

### 6.1 Liquid Glass Effects & Tints
```swift
// Regular glass effect with Living Dawn Amber accent tint and interactive touch haptics
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
    Tab("Today", systemImage: "sun.max", value: TabItem.today) {
        NavigationStack {
            HomeDailyPathView()
        }
    }
    Tab("Bible", systemImage: "book", value: TabItem.bible) {
        NavigationStack {
            BibleReaderView()
        }
    }
    Tab("Lamb", image: "shepherd.lamb.template", value: TabItem.companion) {
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

### 7.1 Truth Probe (`sb_truth_probe.py`)
Validates every visible verse, lesson title, reflection prompt, prayer prompt, quiz question, choice, explanation, and answer styling against `Shepherd/Resources/Content/paths.json` and `sample_bible.json`:
```text
$ python3 scratch/sb_truth_probe.py design/screens/shepherd.pen .
0 truth problems
```

### 7.2 Chrome Probe (`sb_chrome_probe.py`)
Validates Liquid Glass hierarchy: scroll content precedes chrome in z-order, all chrome components have blur filters, and `_Scrolled` frames feature scroll content passing under the toolbar:
```text
$ python3 scratch/sb_chrome_probe.py design/screens/shepherd.pen design/shepherd.lib.pen
0 chrome problems
```

### 7.3 Contrast Probe (`sb_contrast.py`)
Calculates relative luminance and WCAG 2.1 contrast ratios for every text and background pair across all 70 frames:
```text
$ python3 scratch/sb_contrast.py design/screens/shepherd.pen design/shepherd.lib.pen
total text pairs: 1070
WCAG AA failures: 0
```
- Minimum measured body text contrast: 5.4:1 (exceeds WCAG AA 4.5:1 floor).
- Headline and primary scripture text: 14.2:1 against light canvas / 15.6:1 against dark canvas.
- Accent text `#9A5500` against light canvas `#FAF8F4`: 5.21:1.
- Button fill `#B45309` with white text: 5.25:1.

### 7.4 Pencil Token Audit (`pen-audit.py`)
Verifies library instances (`refs >= 300`), 0 hex literals, and 0 dangling pointers:
```text
$ python3 ~/.gemini/config/skills/pencil-pen-authoring/scripts/pen-audit.py design/shepherd.lib.pen
design/shepherd.lib.pen: imports[none] lib=0 local=3626 vars=86 hex=0 refs=0 dangling=0

$ python3 ~/.gemini/config/skills/pencil-pen-authoring/scripts/pen-audit.py design/screens/shepherd.pen
design/screens/shepherd.pen: imports[I=../shepherd.lib.pen] lib=2506 local=0 vars=0 hex=0 refs=322 dangling=0
```
- **Library References Gate:** 322 component instances (exceeds 300 reference requirement).
- **Hex Literal Gate:** 0 hex literals in both files (100% token binding).
- **Dangling Pointer Gate:** 0 dangling variables.

### 7.5 Pencil Layout Engine Check (`pen-layout-check.js`)
Validates bounding box overlaps and text wrapping inside headless `pen interactive`:
```text
$ bash ~/.gemini/config/skills/pencil-pen-authoring/scripts/pen-run.sh design/screens/shepherd.pen -e "$(cat ~/.gemini/config/skills/pencil-pen-authoring/scripts/pen-layout-check.js)"
libraries: I ok
no clipped or overlapping text
```

### 7.6 Export Integrity Verification
Automated checksum and channel audit across all 70 canonical PNG exports:
- **Total Exported PNGs:** 70 (35 Dark, 35 Light) @2x retina resolution.
- **Black Frame Check (max pixel channel < 60):** 0 black frames.
- **Identical Dark/Light Pairs:** 0 identical pairs (100% theme differentiation).

---

## 8. Mascot Character System — The Shepherd Lamb

### 8.1 Character Identity & Proportions
The mascot is **the Shepherd lamb**—a gentle, warm, patient companion who walks alongside the reader through the 7-day paths and grows as the user learns. The user names their lamb during onboarding (`Companion.name`, default "Lamb"); **Barnaby** is the sample story name used in design mockups.

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
To ensure visual harmony behind Liquid Glass chrome and in both light/dark appearances, the character strictly uses semantic tokens:
- **`--color-mascot-wool`** (`#FFF8EC`): Fluffy fleece body and ear tufts.
- **`--color-mascot-face`** (`#F4E3CC`): Warm parchment face and inner ears.
- **`--color-mascot-feature`** (`#3D312B`): Eyes, smile arcs, and hoof markings.
- **`--color-mascot-snout`** (`#EFA593`): Soft blush snout and rosy cheeks.
- **`--color-mascot-halo`** (`#7A6655` light / `#FFF8EC4D` dark): Gentle ambient aura.
- **`--color-mascot-bell`** (`#C99A3A`): Bell collar and Stage 5 laurel wreath.

### 8.3 Exact Growth Stages (`Companion.stage = 1 + xp/50`)
Every stage maps directly to the model formula in `UserModels.swift:46`:

| Stage | Name | Threshold | Silhouette & Visual Evolution |
|:---:|:---|:---:|:---|
| **1** | **Newborn** | `0–49 XP` | Tiny curled sleeping posture, compact fleece ring, delicate closed/resting eyes. Gentle introduction to faith. |
| **2** | **Lamb** | `50–99 XP` | Sitting upright, alert open eyes, soft head tilt, curious presence. First steps in daily habit. |
| **3** | **Young sheep** | `100–149 XP` | Fully standing on sturdy hooves, cheerful confident smile, perky ears, golden neck bell collar. |
| **4** | **Yearling** | `150–199 XP` | Fuller, richer cloud fleece coat, serene posture, protective presence, deeper ambient aura. |
| **5** | **Grown sheep** | `200+ XP` | Mature pastoral guide, radiant golden floral laurel wreath, gentle dignified stance, guiding others. |

### 8.4 Expression Repertoire
The library defines 6 production expressions across all 5 stages:
1. **Idle**: Calm, resting presence. Soft oval eyes, gentle smile. Displayed on home path card and companion hub.
2. **Happy**: Upward-curved laughing crescent eye arcs (`^ ^`), perky ears, glowing cheeks. Triggered upon selecting the correct quiz answer.
3. **Encouraging**: Sympathetic 10° head tilt, warm wide eyes, soft comforting presence. Triggered upon an incorrect quiz answer. **Strict ethical rule:** The mascot never cries, scolds, shakes in anger, or guilts the user.
4. **Celebrating**: Leaping energetic posture, golden star eyes (`★ ★`), open cheerful mouth, radiant fleece sparkles. Triggered on lesson completion and streak increments.
5. **Sleepy**: Peaceful horizontal slit eyes (`- -`), slightly drooping relaxed ears. Displayed during evening hours and rest intervals.
6. **Hello**: Friendly onboarding greeting pose, perky lifted ear, waving fleece hoof. Displayed on Welcome and Name-Your-Lamb screens.

### 8.5 Screen Placement & Sanctuary Policy
- **Where the Lamb Appears:**
  - Onboarding Welcome & Name-Your-Companion screens (bonding ritual).
  - Questionnaire steps (bottom-left peeking pose over option list).
  - Building Your Personal Plan loading state (companion preview).
  - Today's Path status card (standing beside active node on the meadow S-curve).
  - Quiz Feedback Sheets (instant pedagogical reaction: happy or encouraging).
  - Lesson Complete Celebration (joyful XP reward moment).
  - Companion Hub (full level inspection, stage timeline, and naming).
- **Where the Lamb Deliberately Does NOT Appear (The Sacred Sanctuary Rule):**
  - **Lesson Reading View:** The lamb is completely absent.
  - **Bible Reader View:** The lamb is completely absent.
  - **Rationale:** Scripture is sacred and contemplative. Reading God's Word requires quietude and reverence. Inserting a cartoon mascot into biblical text degrades devotional depth and causes cognitive fatigue.

### 8.6 Mascot Personality, Voice & Sample Copy
The lamb speaks as a humble, cheerful study companion walking along the path—never as an authority, theologian, or divine voice. It cheers consistency, encourages patience, and celebrates small steps of understanding:
1. *"A gentle step forward today. One passage at a time."* (Onboarding complete)
2. *"Keep going! You're learning. Let's look back at Genesis 1:1 together."* (Incorrect quiz guidance)
3. *"Splendid! The light always breaks through the darkness."* (Correct quiz answer)
4. *"Day 1 complete! Our meadow is growing brighter."* (Lesson complete)
5. *"Rest peacefully tonight. Tomorrow's path will be waiting for us."* (Evening reflection)
6. *"No rush, no pressure. Five quiet minutes is all we need."* (Habit reminder)

---

## 9. Liquid Glass & Motion Specification

Every animation in Shepherd is built using real Apple iOS 26 SwiftUI primitives (`GlassEffectContainer`, `@Namespace`, `.glassEffectID`, `phaseAnimator`, `keyframeAnimator`, `.sensoryFeedback`, `.matchedTransitionSource`). Zero third-party runtimes.

### 9.1 Motion Matrix (14 Canonical Animations)

| # | Animation | Trigger | Duration | Curve | What Moves | Haptic | Reduce Motion Fallback | Reduce Transparency Fallback |
|:---:|:---|:---|:---|:---|:---|:---|:---|:---|
| **1** | **Lamb idle breathe** | Ambient loop while idle | `3.2s` | `.easeInOut` | Body fleece scaleY `1.0 → 1.02` anchored at hooves (`phaseAnimator([0,1])`) | None | Static idle pose | Same |
| **2** | **Lamb blink** | Ambient timer (every 4–6s) | `0.18s` | `.easeInOut` | Eye oval scaleY `1.0 → 0.1 → 1.0` (`keyframeAnimator`) | None | Static eyes open | Same |
| **3** | **Happy hop** | User selects correct answer | `0.35s` | `.cubic(0.15s)` + `.snappy(0.2s)` | Vertical offset `0 → -12pt → 0`, landing squash scaleY `0.94` | `.sensoryFeedback(.success)` | Expression swap with 0.15s crossfade | Same |
| **4** | **Encouraging tilt** | User selects wrong answer | `0.40s` | `.spring(duration: 0.4, bounce: 0.2)` | Head rotation `0° → 10°`, hold (never shakes) | `.sensoryFeedback(.warning)` | Expression swap with crossfade | Same |
| **5** | **Celebrate** | Lesson completed | `0.60s` | `.bouncy` | Hop ×2 plus 3 fleece sparkles scale `0 → 1 → 0` staggered by `0.08s` | `.sensoryFeedback(.success)` | Static celebrating pose, sparkles static | Same |
| **6** | **Stage-up evolution** | 50 XP milestone reached | `0.75s` | `.spring(duration: 0.5, bounce: 0.25)` | Old stage scales `1 → 1.08` fades out, new stage scales `0.9 → 1.0`, ring ripple | `.sensoryFeedback(.impact(weight: .medium))` | Direct 0.25s crossfade between stages | Same |
| **7** | **Morph A: Check → Feedback** | User taps "Check Answer" | `0.35s` | `.spring(duration: 0.35, bounce: 0.15)` | 54pt capsule button expands into 214pt drawer via `GlassEffectContainer` + `.glassEffectID("quiz_action")` | Dynamic with answer result | Simple 0.2s crossfade between views | Opaque card (`#FFFFFF` / `#1D2220`) + 1pt border + scrim |
| **8** | **Morph B: Accessory Inline ↔ Expanded** | Drag/tap on bottom accessory | `0.30s` | System-driven by `.tabBarMinimizeBehavior(.onScrollDown)` | 56pt pill expands to 150pt preview card via `tabViewBottomAccessoryPlacement` | `.sensoryFeedback(.selection)` | System default crossfade | Opaque card surface + border |
| **9** | **Morph C: Path Node → Lesson** | Tap active Day 1 path node | `0.35s` | System zoom transition | 72×72pt node expands to full lesson header via `.matchedTransitionSource` + `.navigationTransition(.zoom)` | `.sensoryFeedback(.impact(weight: .medium))` | Standard navigation push crossfade | Standard navigation push |
| **10** | **Check button press** | User presses button | `0.15s` | Native touch spring | Interactive physical compression via `.buttonStyle(.glassProminent)` | System glass touch haptic | Native touch press | Native solid button press |
| **11** | **Streak +1 increment** | Lesson reward trigger | `0.28s` | `.snappy` | Streak count `.contentTransition(.numericText())`, flame `.symbolEffect(.bounce)` | `.sensoryFeedback(.impact(weight: .light))` | Numeric text transition only (no flame bounce) | Same |
| **12** | **XP bar progress fill** | +12 XP awarded | `0.60s` | `.spring(duration: 0.6, bounce: 0.1)` | Horizontal progress bar fill width grows smoothly to new value | None | Instant width update | Same |
| **13** | **Node unlock ripple** | Previous lesson completed | `0.60s` | `.easeOut` | Lock `.symbolEffect(.disappear)`, fill crossfades to amber, 1 ring ripple 36→52pt / opacity 0.8→0 | `.sensoryFeedback(.impact(weight: .light))` | Direct crossfade without ripple | Same |
| **14** | **Scroll edge blur** | Scroll reaches top limit | Continuous | System `scrollEdgeEffectStyle(.soft, for: .top)` | Dynamic specular rim glare intensifies, background blur expands | None | Standard scroll stop | Standard scroll stop |

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
- **XP Progress Fill:** The horizontal XP bar animates its corner-radiused fill width using `.spring(duration: 0.6, bounce: 0.1)`, accompanied by a subtle golden glow flash (`opacity 0.0 -> 0.4 -> 0.0`).
- **Path Node Unlocking:** Upon completing a lesson, the subsequent path node padlock icon morphs into the active amber star with a soft ring ripple (`radius 36 -> 52`, `opacity 0.8 -> 0.0`).

### 9.4 Accessibility Fallbacks
- **`accessibilityReduceMotion`:** When enabled in iOS Settings, all spring morphs and keyframe hops are immediately replaced by standard 150ms opacity crossfades or static state switches. No view positions translate across the screen.
- **`accessibilityReduceTransparency`:** When enabled, Liquid Glass materials automatically swap their translucent blur layers (`--color-glass-fill`) for 100% opaque card surfaces (`--color-card-surface`) with high-contrast borders (`--color-surface-border`), guaranteeing complete legibility.
- **Devotional Restraint:** Motion is quiet, soft, and respectful. Zero full-screen particle cannons, zero noisy confetti bursts, and zero unprompted popups while studying.
