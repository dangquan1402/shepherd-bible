# Pasture: iOS 26 Liquid Glass design

Design files for the Pasture iPhone app (formerly Shepherd): a Bible-habit app with a black-faced lamb companion, drawn for iOS 26 Liquid Glass. Brand direction **Flock** (ultramarine for action, sunflower for reward).

| File | What it holds |
|---|---|
| `shepherd.lib.pen` | The library: tokens (light/dark), 30 lamb variants, 7 lamb avatars, brand mark / wordmark / lockups / app icon, glass navigation, controls, rows, feedback sheets |
| `screens/shepherd.pen` | Every screen as a light frame and a dark frame, built from library instances (imports the library as `I`) |
| `exports/*.png` + `exports/index.tsv` | One 2× PNG per frame (`Screen_State_Light.png` / `_Dark.png`); `index.tsv` maps frame id to file |
| `research.md` | Refero references, reference lock, decision ledger |
| `tools/readme_tables.py` | Regenerates the token, component, frame and sample-content sections below from the files |
| `../tools/brand/` | The brand source: `tokens.py` (every colour token + the AA gate), `lambgen.py` (the lamb generator), `apply_design.py` (writes both into these files), `brandart.py` (app icon, wordmark) |

Sections marked *generated* are written by `python3 design/tools/readme_tables.py`. Do not edit them by hand.

---

## 1. Platform and captain decisions

- **D1, deployment target: iOS 26.** The app's minimum target moves from iOS 17 (the repo README) to **iOS 26**. Liquid Glass (`.glassEffect`, `GlassEffectContainer`, `.buttonStyle(.glass)` / `.glassProminent`, `tabViewBottomAccessory`, `.tabBarMinimizeBehavior`, `scrollEdgeEffectStyle`) is iOS 26 only. No `.ultraThinMaterial` fallback is designed. The SwiftUI animators used for the lamb (`phaseAnimator`, `keyframeAnimator`, `sensoryFeedback`) exist from iOS 17.
- **D2, path catalogue:** the real path (`beginner-7`) plus one honest "More paths are coming" row, with no titles and no counts (`Path_Overview`).
- **D3, trial reminder:** no reminder promise. The paywall's Day 5 row reads "Cancel anytime before Day 7". Settings has no reminder row.

## 2. Design inputs

### 2.1 What the code exposes

| Model / service | Fields used by the design | Where it shows |
|---|---|---|
| `UserProfile` | `goal` (`grow_daily` / `understand` / `peace` / `new`), `experienceLevel` (`beginner` / `some` / `regular`), `dailyMinutes` (5 / 10 / 15) | Onboarding steps 2–4 use the code's labels and values exactly |
| `Companion` | `name` (default "Lamb", set in onboarding), `xp`, `stage = max(1, min(5, 1 + xp / 50))` | Lamb stage everywhere; Companion screen; XP bars |
| `StreakState` | `current` (starts at 0; `markCompleted` sets 1), `best`, `freezesLeft` (no logic consumes it) | Streak chip in the Today toolbar; reward chip. No freeze state is drawn: nothing in the code uses `freezesLeft` yet |
| `LessonProgress` | `lessonId`, `quizScore` | Path node done / current state |
| `EntitlementState` | `isPremium` | Settings "Pasture Premium" row |
| `LessonView.complete` | `addXP(10 + score)`, `markCompleted()` | Reward: +12 XP for 2/2 correct on Day 1 (+11 for 1/2, +10 for 0/2) |
| `StoreKitManager` | `premium.yearly`, `premium.monthly`, `Product.displayPrice` | Paywall plan cards; prices in the frames are placeholders |
| `ContentStore.verse(ref:)` | WEB text by `BOOK.c.v` | Every verse in every frame |

### 2.2 Verbatim copy kept from the scaffold

Onboarding: "Welcome to Pasture", "A few minutes a day. Scripture that sticks. Everything stays on your phone.", "What’s your goal?", "How familiar are you?", "How many minutes a day?", "Name your companion", "Continue", "See my plan". Paywall: "Grow with Shepherd Premium", the four features "Full learning paths", "Streak freezes", "Companion outfits", "Widgets & reminders", "Yearly · 7-day free trial · Best value · Most popular", "Monthly · 7-day free trial", "Start free trial", "Continue with free path". Lesson: "Take the quiz", "Prayer". Settings: "No account. Progress stays on this device.", "No ad trackers in v1." (shown as "Ad trackers · None in v1").

Copy changed on purpose: the building step reads "Preparing your path…" (one path exists, nothing is personalised) and its rows read "Goal: Grow a daily habit" and "Daily goal: 5 min". The quiz drops "Question 1 of 2" for a progress bar plus "Day 1".

### 2.3 Sample content (*generated*, pasted from the JSON)

<!-- gen:content -->
Path `beginner-30`: "First Steps: 30 Days with God" (level `beginner`, `estimatedDays` 30, 30 lessons). Translation label in the JSON: `WEB`.

| Day | Lesson id | Title | Verses | Questions (explain present?) |
|---|---|---|---|---|
| 1 | `day1` | In the beginning | GEN.1.1, GEN.1.3 | `day1-q1` yes; `day1-q2` yes |
| 2 | `day2` | Made in God's image | GEN.1.26, GEN.1.27 | `day2-q1` yes; `day2-q2` yes |
| 3 | `day3` | The Word became flesh | JHN.1.1, JHN.1.14 | `day3-q1` yes; `day3-q2` yes |
| 4 | `day4` | God so loved | JHN.3.16, JHN.3.17 | `day4-q1` yes; `day4-q2` yes |
| 5 | `day5` | The Lord is my shepherd | PSA.23.1, PSA.23.4 | `day5-q1` yes; `day5-q2` yes |
| 6 | `day6` | Light of the world | MAT.5.14, MAT.5.16 | `day6-q1` yes; `day6-q2` yes |
| 7 | `day7` | Pray like this | MAT.6.9, MAT.6.11, PHP.4.6, PHP.4.7 | `day7-q1` yes; `day7-q2` yes; `day7-q3` yes |
| 8 | `beginner-30.d08` | The good shepherd | JHN.10.11, JHN.10.14, JHN.10.27 | `beginner-30.d08.q1` yes; `beginner-30.d08.q2` yes; `beginner-30.d08.q3` yes |
| 9 | `beginner-30.d09` | The one that was lost | LUK.15.4, LUK.15.5, LUK.15.6, LUK.15.7 | `beginner-30.d09.q1` yes; `beginner-30.d09.q2` yes; `beginner-30.d09.q3` yes |
| 10 | `beginner-30.d10` | The father runs | LUK.15.20, LUK.15.21, LUK.15.22, LUK.15.24 | `beginner-30.d10.q1` yes; `beginner-30.d10.q2` yes; `beginner-30.d10.q3` yes |
| 11 | `beginner-30.d11` | A gift, not a wage | EPH.2.8, EPH.2.9, EPH.2.10 | `beginner-30.d11.q1` yes; `beginner-30.d11.q2` yes; `beginner-30.d11.q3` yes |
| 12 | `beginner-30.d12` | While we were yet sinners | ROM.5.6, ROM.5.7, ROM.5.8 | `beginner-30.d12.q1` yes; `beginner-30.d12.q2` yes; `beginner-30.d12.q3` yes |
| 13 | `beginner-30.d13` | Faith for the next step | HEB.11.1, HEB.11.2, HEB.11.8 | `beginner-30.d13.q1` yes; `beginner-30.d13.q2` yes; `beginner-30.d13.q3` yes |
| 14 | `beginner-30.d14` | Come and see | JHN.1.43, JHN.1.45, JHN.1.46 | `beginner-30.d14.q1` yes; `beginner-30.d14.q2` yes; `beginner-30.d14.q3` yes |
| 15 | `beginner-30.d15` | The way | JHN.14.1, JHN.14.2, JHN.14.5, JHN.14.6 | `beginner-30.d15.q1` yes; `beginner-30.d15.q2` yes; `beginner-30.d15.q3` yes |
| 16 | `beginner-30.d16` | Remain in me | JHN.15.4, JHN.15.5, JHN.15.9 | `beginner-30.d16.q1` yes; `beginner-30.d16.q2` yes; `beginner-30.d16.q3` yes |
| 17 | `beginner-30.d17` | A lamp for my feet | PSA.119.18, PSA.119.103, PSA.119.105 | `beginner-30.d17.q1` yes; `beginner-30.d17.q2` yes; `beginner-30.d17.q3` yes |
| 18 | `beginner-30.d18` | Equipped for good | 2TI.3.14, 2TI.3.15, 2TI.3.16, 2TI.3.17 | `beginner-30.d18.q1` yes; `beginner-30.d18.q2` yes; `beginner-30.d18.q3` yes |
| 19 | `beginner-30.d19` | Doers of the word | JAS.1.22, JAS.1.23, JAS.1.24, JAS.1.25 | `beginner-30.d19.q1` yes; `beginner-30.d19.q2` yes; `beginner-30.d19.q3` yes |
| 20 | `beginner-30.d20` | The greatest commandment | MAT.22.36, MAT.22.37, MAT.22.39, MAT.22.40 | `beginner-30.d20.q1` yes; `beginner-30.d20.q2` yes; `beginner-30.d20.q3` yes |
| 21 | `beginner-30.d21` | Love is patient | 1CO.13.4, 1CO.13.5, 1CO.13.6, 1CO.13.7 | `beginner-30.d21.q1` yes; `beginner-30.d21.q2` yes; `beginner-30.d21.q3` yes |
| 22 | `beginner-30.d22` | Who is my neighbor? | LUK.10.29, LUK.10.33, LUK.10.34, LUK.10.36, LUK.10.37 | `beginner-30.d22.q1` yes; `beginner-30.d22.q2` yes; `beginner-30.d22.q3` yes |
| 23 | `beginner-30.d23` | Seventy times seven | MAT.6.12, MAT.18.21, MAT.18.22 | `beginner-30.d23.q1` yes; `beginner-30.d23.q2` yes; `beginner-30.d23.q3` yes |
| 24 | `beginner-30.d24` | Bear with one another | COL.3.12, COL.3.13, COL.3.14 | `beginner-30.d24.q1` yes; `beginner-30.d24.q2` yes; `beginner-30.d24.q3` yes |
| 25 | `beginner-30.d25` | If we confess | 1JN.1.7, 1JN.1.8, 1JN.1.9 | `beginner-30.d25.q1` yes; `beginner-30.d25.q2` yes; `beginner-30.d25.q3` yes |
| 26 | `beginner-30.d26` | Together | ACT.2.42, ACT.2.44, ACT.2.46, ACT.2.47 | `beginner-30.d26.q1` yes; `beginner-30.d26.q2` yes; `beginner-30.d26.q3` yes |
| 27 | `beginner-30.d27` | Don't give up | HEB.10.23, HEB.10.24, HEB.10.25 | `beginner-30.d27.q1` yes; `beginner-30.d27.q2` yes; `beginner-30.d27.q3` yes |
| 28 | `beginner-30.d28` | He is risen | LUK.24.2, LUK.24.3, LUK.24.5, LUK.24.6 | `beginner-30.d28.q1` yes; `beginner-30.d28.q2` yes; `beginner-30.d28.q3` yes |
| 29 | `beginner-30.d29` | All things new | REV.21.3, REV.21.4, REV.21.5 | `beginner-30.d29.q1` yes; `beginner-30.d29.q2` yes; `beginner-30.d29.q3` yes |
| 30 | `beginner-30.d30` | Looking back, walking on | GEN.1.1, JHN.3.16, LUK.15.20, JHN.15.5, LUK.24.6 | `beginner-30.d30.q1` yes; `beginner-30.d30.q2` yes; `beginner-30.d30.q3` yes |

**Day 1, verbatim** (`day1`)

- Genesis 1:1 (WEB): "In the beginning, God created the heavens and the earth."
- Genesis 1:3 (WEB): "God said, “Let there be light,” and there was light."
- Body: "The Bible opens with God, not with us: "In the beginning, God created the heavens and the earth." Before anything else is said, the world is God's work.  The next verse describes the earth as "formless and empty," with darkness over the deep (Genesis 1:2). Then God speaks: "Let there be light." Light is the first thing he makes, and the rest of the chapter brings order and life out of that emptiness, day by day. Again and again God looks at what he has made and calls it good (Genesis 1:31).  **Reflection:** Where in your life does it feel dark or unformed right now? What would it mean to invite God to speak there?  *Study aid: Christians read the days of Genesis 1 in different ways, some as ordinary days and some as a literary pattern. This lesson looks at what the passage says about God.*"
- Prayer: "Thank you, God, for creating all things and for bringing light into darkness."
- `day1-q1` "Who created the heavens and the earth?": A "Angels" · B "God" · C "Moses" · D "Kings"; correct B; explain: "Genesis 1:1: \"In the beginning, God created the heavens and the earth.\""
- `day1-q2` "What did God say first?": A "Let there be land" · B "It is finished" · C "Let there be light" · D "Follow me"; correct C; explain: "Genesis 1:3. God speaks, and light is the first thing he makes."

Bundled Bible: World English Bible, 66 books, 1189 chapters.
<!-- /gen:content -->

### 2.4 Weaknesses of the scaffold this design answers

1. The lamb is an emoji ("🐑") everywhere, including Home and the paywall.
2. Home is a text card, not a path; the quiz has no feedback, no verse, no reward.
3. Flat `List` chrome with no glass, no scroll-edge treatment, no tab-bar accessory.
4. The paywall has no auto-renew disclosure, no Restore / Terms / Privacy, and no purchase states.
5. The tab bar uses `hare.fill` for the lamb.

## 3. Identity

Direction **Flock** (chosen from three in `data/sb-brand/directions`, outside the repo): a mascot-led brand that stays devotional.

- **Canvas:** an almost-white lavender (`#FBFAFF`) by day, **midnight indigo** (`#14122E`, card `#1E1B42`) by night. The dark is chromatic on purpose: Liquid Glass reads as tinted glass on it, not grey on black. A periwinkle-to-sunrise sky sits behind most screens, with vivid light meadow hills on Today.
- **Accent: ultramarine.** Text `#3431D6` / `#B3B2FF`, fill `#3D3AE8` / `#5E5CF2`. It is for actions, the current node, progress, icon tints and the lamb's bandana. The dark fill sits in the narrow band that carries a white label at 4.5:1 *and* clears 3:1 against the dark surfaces as an icon tint.
- **Sunflower (`--color-gold*`) is for reward and celebration only:** XP, streak, sparkles, the bell, the crown's centres, the sunlit path. It never colours routine chrome.
- **Logo.** A lowercase wordmark `pasture` outlined from **Baloo 2 ExtraBold** (SIL Open Font License 1.1, Ek Type), so no font ships. The mark is the lamb's front face on an ultramarine chip. `Brand/Lockup` is used centred above the lamb on Onboarding_Welcome; `Brand/Lockup/Compact` is used at the top left of the paywall.
- **App icon.** The front face filling an ultramarine gradient tile (`--color-icon-top` / `-bottom`). The dark appearance uses the same face on midnight indigo. Tinted is a grayscale source with the face lifted to mid-grey so the silhouette survives the tint; clear is a white head silhouette with the eyes cut out. All four come from `tools/brand/brandart.py`.
- **Devotional, not a kids' app:** New York stays for titles, verses and prayer, scripture screens stay lamb-free, and motion stays calm (section 9).
- **Green and red are reserved for quiz correctness** (`--color-success*`, `--color-error*`). Nothing else uses them. The Settings restore toast uses a neutral info icon for this reason.
- **The lamb** is the character (section 6). It lives on the path, in feedback, in onboarding and on the reward. It is deliberately absent from Lesson reading and the Bible reader.
- **Type.** SF Pro for UI and New York (`.fontDesign(.serif)`) for titles, verses and prayer. *Render proxies:* Pencil's renderer has no Apple system fonts, so the `--font-body` / `--font-sans` tokens hold **Inter** and `--font-display` / `--font-serif` hold **Newsreader**. Ship SF Pro and New York; sizes and weights carry over.

## 4. Tokens (*generated*)

<!-- gen:tokens -->
109 variables in `shepherd.lib.pen` (theme axis `mode`: light / dark).

**Colour: text and surfaces**

| Token | Light | Dark |
|---|---|---|
| `--color-canvas-bg` | `#FBFAFF` | `#14122E` |
| `--color-card-surface` | `#FFFFFF` | `#1E1B42` |
| `--color-surface-sunken` | `#F0EFFA` | `#262351` |
| `--color-surface-border` | `#E1DFF2` | `#322F63` |
| `--color-text-primary` | `#18163A` | `#F6F5FF` |
| `--color-text-secondary` | `#4C4970` | `#C2BFE6` |
| `--color-text-tertiary` | `#5F5C84` | `#A19DCB` |
| `--color-on-accent` | `#FFFFFF` | `#FFFFFF` |
| `--color-transparent` | `#00000000` | `#00000000` |
| `--color-phone-island` | `#000000` | `#000000` |
| `--color-phone-camera` | `#1A1A2E` | `#1A1A2E` |
| `--color-phone-sensor` | `#111111` | `#111111` |
| `--color-canvas-clear` | `#FBFAFF00` | `#14122E00` |
| `--color-canvas-veil` | `#FBFAFFB3` | `#14122EB3` |

**Colour: accent, gold, reward**

| Token | Light | Dark |
|---|---|---|
| `--color-accent` | `#3431D6` | `#B3B2FF` |
| `--color-accent-fill` | `#3D3AE8` | `#5E5CF2` |
| `--color-accent-subtle` | `#E9E9FF` | `#2D2A66` |
| `--color-gold` | `#8A5200` | `#FFD23F` |
| `--color-gold-fill` | `#FFC21A` | `#FFC21A` |
| `--color-gold-subtle` | `#FFF5CF` | `#3A3326` |
| `--color-node-current-ring` | `#FFFFFF` | `#FFF7D6` |
| `--color-node-glow` | `#3D3AE855` | `#FFD23F40` |
| `--color-accent-fill-deep` | `#2421A8` | `#2A27A6` |
| `--color-accent-subtle-deep` | `#C9C8FA` | `#3B3880` |
| `--color-node-locked` | `#FFFFFF` | `#29265A` |
| `--color-node-locked-deep` | `#D9D7EE` | `#151236` |

**Colour: quiz correctness (quiz only)**

| Token | Light | Dark |
|---|---|---|
| `--color-success` | `#137135` | `#4ADE80` |
| `--color-success-subtle` | `#EAF7EE` | `#173528` |
| `--color-error` | `#B91C1C` | `#FF8A8A` |
| `--color-error-subtle` | `#FDF0EF` | `#3B1E33` |
| `--color-success-fill` | `#137135` | `#15803D` |
| `--color-success-deep` | `#0D4F25` | `#0E5A2B` |

**Colour: Liquid Glass**

| Token | Light | Dark |
|---|---|---|
| `--color-glass-fill` | `#FFFFFF94` | `#221F4CA6` |
| `--color-glass-stroke` | `#D6D4EE` | `#FFFFFF30` |
| `--color-glass-specular` | `#FFFFFFE6` | `#FFFFFF4D` |
| `--color-shadow-glass` | `#18163A14` | `#00000040` |
| `--color-shadow-glass-heavy` | `#18163A26` | `#00000073` |
| `--color-scrim` | `#18163A59` | `#07061899` |
| `--color-glass-spec-top` | `#FFFFFFE6` | `#FFFFFF80` |
| `--color-glass-spec-mid` | `#FFFFFF00` | `#FFFFFF00` |
| `--color-glass-spec-bottom` | `#4C49704D` | `#FFFFFF1F` |
| `--color-glass-inner-hi` | `#FFFFFFA6` | `#FFFFFF45` |
| `--color-tab-selection` | `#3D3AE81A` | `#FFFFFF24` |
| `--color-scrim-soft` | `#18163A14` | `#07061840` |

**Colour: meadow illustration**

| Token | Light | Dark |
|---|---|---|
| `--color-meadow-sky` | `#ECEEFF` | `#1A1848` |
| `--color-meadow-hill-distant` | `#D2F0AE` | `#1C3A4E` |
| `--color-meadow-hill-near` | `#A3DD72` | `#25525F` |
| `--color-meadow-path` | `#FFF1BF` | `#3A3772` |
| `--color-meadow-path-border` | `#F0D47E` | `#4C4994` |
| `--color-meadow-sky-bottom` | `#FFF4D1` | `#23205A` |
| `--color-meadow-hill-mid` | `#BCE890` | `#204656` |
| `--color-meadow-sky-clear` | `#ECEEFF00` | `#1A184800` |
| `--color-meadow-sky-veil` | `#ECEEFFB3` | `#1A1848B3` |

**Colour: lamb**

| Token | Light | Dark |
|---|---|---|
| `--color-mascot-fleece` | `#FFFFFF` | `#FFFFFF` |
| `--color-mascot-fleece-shade` | `#ECE6DC` | `#ECE6DC` |
| `--color-mascot-face` | `#2A2526` | `#2A2526` |
| `--color-mascot-features` | `#141012` | `#141012` |
| `--color-mascot-far-legs` | `#1A1617` | `#1A1617` |
| `--color-mascot-blush` | `#FF9EB1` | `#FF9EB1` |
| `--color-mascot-outline` | `#2A252600` | `#2A252600` |
| `--color-mascot-shadow` | `#18163A22` | `#00000066` |
| `--color-mascot-tongue` | `#FF7D8F` | `#FF7D8F` |
| `--color-mascot-bell` | `#FFC21A` | `#FFC21A` |
| `--color-mascot-hoof` | `#100D0E` | `#100D0E` |
| `--color-mascot-catchlight` | `#FFFFFF` | `#FFFFFF` |
| `--color-mascot-legs` | `#2A2526` | `#2A2526` |
| `--color-mascot-eye-white` | `#FFFFFF` | `#FFFFFF` |
| `--color-mascot-mouth` | `#5B1E2E` | `#5B1E2E` |
| `--color-mascot-flower` | `#FF9EB1` | `#FF9EB1` |
| `--color-mascot-zz` | `#8C86B8` | `#A19DCB` |

**Colour: app icon (light = default appearance, dark = dark appearance)**

| Token | Light | Dark |
|---|---|---|
| `--color-icon-top` | `#4B48F2` | `#25225A` |
| `--color-icon-bottom` | `#2E2BD0` | `#14122E` |

**Colour: design notes (not shipped UI)**

| Token | Light | Dark |
|---|---|---|
| `--color-note` | `#6D28D9` | `#C4B5FD` |
| `--color-note-subtle` | `#F1EAFE` | `#2A2144` |

**Type**

| Token | Light | Dark |
|---|---|---|
| `--font-sans` | `Inter` | `Inter` |
| `--font-serif` | `Newsreader` | `Newsreader` |
| `--font-mono` | `SF Mono` | `SF Mono` |
| `--text-xs` | `11` | `11` |
| `--text-caption` | `12` | `12` |
| `--text-footnote` | `13` | `13` |
| `--text-subheadline` | `15` | `15` |
| `--text-callout` | `16` | `16` |
| `--text-body` | `17` | `17` |
| `--text-headline` | `17` | `17` |
| `--text-title3` | `20` | `20` |
| `--text-title2` | `22` | `22` |
| `--text-title1` | `28` | `28` |
| `--text-large-title` | `34` | `34` |
| `--text-ax3-body` | `40` | `40` |
| `--weight-regular` | `400` | `400` |
| `--weight-medium` | `500` | `500` |
| `--weight-semibold` | `600` | `600` |
| `--weight-bold` | `700` | `700` |
| `--font-body` | `Inter` | `Inter` |
| `--font-display` | `Newsreader` | `Newsreader` |

**Radius and spacing**

| Token | Light | Dark |
|---|---|---|
| `--radius-xs` | `4` | `4` |
| `--radius-sm` | `8` | `8` |
| `--radius-md` | `14` | `14` |
| `--radius-lg` | `20` | `20` |
| `--radius-xl` | `28` | `28` |
| `--radius-pill` | `999` | `999` |
| `--space-1` | `4` | `4` |
| `--space-2` | `8` | `8` |
| `--space-3` | `12` | `12` |
| `--space-4` | `16` | `16` |
| `--space-5` | `20` | `20` |
| `--space-6` | `24` | `24` |
| `--space-8` | `32` | `32` |
| `--space-10` | `40` | `40` |
<!-- /gen:tokens -->

Type scale (Dynamic Type style → size used in the frames): Large Title 34 (Home, Paths, Settings, lesson title, all in the serif), Title1 28 (onboarding questions), Title2 22 (feedback title), Title3 20, Headline/Body 17, Callout 16, Subheadline 15, Footnote 13, Caption2 11. Nothing is below 11 pt.

## 5. Components and Liquid Glass

### 5.1 Library components (*generated*)

<!-- gen:components -->
79 published components (30 lamb variants + 49 others).

| Component | Size (pt) | Children | Purpose |
|---|---|---|---|
| `Icon/LambGlyph` | 24×24 | 1 path | 24 pt lamb template glyph for the Lamb tab |
| `Mascot/CharacterSheet` | 1240×719 | 30 ref, 21 text | all 30 lamb variants with stage labels |
| `Sys/StatusBar` | 402×54 | 1 frame, 3 icon, 1 text | iPhone system chrome (status bar with black Dynamic Island, home indicator) |
| `Sys/HomeIndicator` | 140×5 |  | iPhone system chrome (status bar with black Dynamic Island, home indicator) |
| `Nav/GlassButton` | 44×44 | 2 frame, 1 icon | 44 pt circular glass toolbar button; icon swapped per use |
| `Nav/StreakChip` | 76×44 | 2 frame, 1 icon, 1 text | glass toolbar chip: flame + current streak |
| `Nav/GlassPillButton` | 96×44 | 2 frame, 1 text | glass text button for toolbars |
| `Nav/TabBar/Today` | 370×62 | 3 frame, 3 icon, 1 ref, 4 text | glass tab bar, one variant per selected tab |
| `Nav/TabBar/Bible` | 370×62 | 3 frame, 3 icon, 1 ref, 4 text | glass tab bar, one variant per selected tab |
| `Nav/TabBar/Lamb` | 370×62 | 3 frame, 3 icon, 1 ref, 4 text | glass tab bar, one variant per selected tab |
| `Nav/TabBar/Settings` | 370×62 | 3 frame, 3 icon, 1 ref, 4 text | glass tab bar, one variant per selected tab |
| `Nav/TabBarMin/Today` | 56×56 | 2 frame, 1 icon | minimized tab bar (single glass circle) after scroll-down |
| `Nav/Accessory/Expanded` | 370×56 | 3 frame, 1 icon, 2 text | tabViewBottomAccessory, expanded placement |
| `Nav/Accessory/Inline` | 298×52 | 2 frame, 1 icon, 1 text | tabViewBottomAccessory, inline placement |
| `Button/Prominent` | 370×56 | 2 frame, 1 text | primary action (.glassProminent tinted ultramarine) |
| `Button/ProminentDisabled` | 370×56 | 1 text | primary action (.glassProminent tinted ultramarine) |
| `Button/Glass` | 370×56 | 2 frame, 1 text | secondary action (.glass) |
| `Button/Text` | 370×44 | 1 text | plain text action |
| `Path/Node/Current` | 84×92 | 4 ellipse, 1 icon | 3D path node (face + deep lip) |
| `Path/Node/Done` | 84×92 | 3 ellipse, 1 icon | 3D path node (face + deep lip) |
| `Path/Node/Locked` | 84×92 | 3 ellipse, 1 icon | 3D path node (face + deep lip) |
| `Path/Node/MilestoneLocked` | 84×92 | 3 ellipse, 1 icon | 3D path node (face + deep lip) |
| `Row/Choice/Neutral` | 370×60 | 1 frame, 2 text | quiz answer row state |
| `Row/Choice/Selected` | 370×60 | 1 frame, 2 text | quiz answer row state |
| `Row/Choice/Correct` | 370×60 | 1 frame, 1 icon, 2 text | quiz answer row state |
| `Row/Choice/Wrong` | 370×60 | 1 frame, 1 icon, 2 text | quiz answer row state |
| `Row/Choice/Revealed` | 370×60 | 1 frame, 1 icon, 2 text | quiz answer row state |
| `Bar/Progress` | 200×8 | 1 frame | progress / XP bar (fill width overridden) |
| `Chip/Stat` | 150×40 | 1 icon, 1 text | reward chip (+XP, streak) |
| `Card/Verse` | 370×None | 2 text | verse card: reference + translation, serif verse text |
| `Row/Option/Default` | 370×60 | 1 ellipse, 1 text | onboarding option row |
| `Row/Option/Selected` | 370×60 | 1 icon, 1 text | onboarding option row |
| `Card/Plan/Selected` | 370×80 | 1 frame, 1 icon, 4 text | paywall plan card |
| `Card/Plan/Default` | 370×80 | 1 ellipse, 1 frame, 4 text | paywall plan card |
| `Row/Settings` | 370×52 | 1 icon, 2 text | settings row (label, value, chevron) |
| `Sheet/Feedback/Correct` | 386×296 | 1 ellipse, 5 frame, 3 ref, 2 text | glass quiz feedback sheet (morph target of Check) |
| `Sheet/Feedback/Wrong` | 386×334 | 1 ellipse, 5 frame, 3 ref, 2 text | glass quiz feedback sheet (morph target of Check) |
| `Avatar/S1/Happy` | 56×56 | 16 path | lamb head-and-shoulders avatar (56 pt, pre-cut to the circle) |
| `Avatar/S1/Encouraging` | 56×56 | 17 path | lamb head-and-shoulders avatar (56 pt, pre-cut to the circle) |
| `Avatar/S1/Idle` | 56×56 | 17 path | lamb head-and-shoulders avatar (56 pt, pre-cut to the circle) |
| `Avatar/S2/Idle` | 56×56 | 17 path | lamb head-and-shoulders avatar (56 pt, pre-cut to the circle) |
| `Avatar/S3/Idle` | 56×56 | 18 path | lamb head-and-shoulders avatar (56 pt, pre-cut to the circle) |
| `Avatar/S4/Idle` | 56×56 | 19 path | lamb head-and-shoulders avatar (56 pt, pre-cut to the circle) |
| `Avatar/S5/Idle` | 56×56 | 21 path | lamb head-and-shoulders avatar (56 pt, pre-cut to the circle) |
| `Brand/Mark` | 40×40 | 1 ellipse, 10 path | logo mark: the lamb face on an ultramarine chip |
| `Brand/Wordmark` | 126.37×30 | 1 path | lowercase wordmark, outlined Baloo 2 ExtraBold (SIL OFL 1.1) |
| `Brand/Lockup` | 177.57×40 | 1 ellipse, 11 path | mark + wordmark, onboarding welcome size |
| `Brand/Lockup/Compact` | 126.86×30 | 1 ellipse, 11 path | mark + wordmark, paywall header size |
| `Brand/AppIcon` | 180×180 | 10 path | app icon artwork at 180 px (60 pt @3x); theme picks default / dark |

| Lamb variant | Artboard (pt) | Vector layers |
|---|---|---|
| `Lamb/S1/Idle` | 139.7×92.4 | 18 paths |
| `Lamb/S1/Happy` | 139.7×92.4 | 17 paths |
| `Lamb/S1/Encouraging` | 139.7×92.4 | 18 paths |
| `Lamb/S1/Celebrating` | 139.7×92.4 | 18 paths |
| `Lamb/S1/Sleepy` | 139.7×92.4 | 17 paths |
| `Lamb/S1/Hello` | 139.7×92.4 | 21 paths |
| `Lamb/S2/Idle` | 116.6×104.5 | 19 paths |
| `Lamb/S2/Happy` | 116.6×104.5 | 18 paths |
| `Lamb/S2/Encouraging` | 116.6×104.5 | 19 paths |
| `Lamb/S2/Celebrating` | 116.6×104.5 | 19 paths |
| `Lamb/S2/Sleepy` | 116.6×104.5 | 17 paths |
| `Lamb/S2/Hello` | 116.6×104.5 | 21 paths |
| `Lamb/S3/Idle` | 130.9×103.4 | 20 paths |
| `Lamb/S3/Happy` | 130.9×103.4 | 19 paths |
| `Lamb/S3/Encouraging` | 130.9×103.4 | 20 paths |
| `Lamb/S3/Celebrating` | 130.9×103.4 | 20 paths |
| `Lamb/S3/Sleepy` | 130.9×103.4 | 17 paths |
| `Lamb/S3/Hello` | 130.9×103.4 | 23 paths |
| `Lamb/S4/Idle` | 138.6×113.3 | 21 paths |
| `Lamb/S4/Happy` | 138.6×113.3 | 20 paths |
| `Lamb/S4/Encouraging` | 138.6×113.3 | 21 paths |
| `Lamb/S4/Celebrating` | 138.6×113.3 | 21 paths |
| `Lamb/S4/Sleepy` | 138.6×113.3 | 17 paths |
| `Lamb/S4/Hello` | 138.6×113.3 | 24 paths |
| `Lamb/S5/Idle` | 146.3×118.8 | 23 paths |
| `Lamb/S5/Happy` | 146.3×118.8 | 22 paths |
| `Lamb/S5/Encouraging` | 146.3×118.8 | 23 paths |
| `Lamb/S5/Celebrating` | 146.3×118.8 | 23 paths |
| `Lamb/S5/Sleepy` | 146.3×118.8 | 19 paths |
| `Lamb/S5/Hello` | 146.3×118.8 | 26 paths |
<!-- /gen:components -->

### 5.2 The glass recipe (every glass node)

| Layer | Value | Why |
|---|---|---|
| Fill | `--color-glass-fill`: white 58% / indigo `#221F4C` 65% | Mostly clear; content shows through; the dark glass carries the indigo tint |
| Backdrop | `background_blur` 24 | The frosting |
| Shadow | 0/8, blur 24, `--color-shadow-glass` | Lifts glass off the content |
| Rim | 1 pt inner stroke `--color-glass-stroke` (light `#D6D4EE`, 1.39:1 on the canvas, so it stays visible in light mode) | Edge definition |
| Specular | 1 pt overlay stroke, linear gradient top→bottom: `--color-glass-spec-top` (white 90% / 45%) → clear at 45% → `--color-glass-spec-bottom` (`#4C4970` 30% / white 12%) | Top-lit highlight with a darker bottom edge |
| Inner highlight | 1 pt line inset 1 pt at the top, `--color-glass-inner-hi` (white 60% / 25%) | The bright lip of real glass |

Rules: glass is only on chrome (toolbar buttons, streak chip, tab bar, accessory, sheets, dialogs, toasts, the Home speech bubble). Never glass on glass: the Bible picker's close button is a plain sunken circle, not glass. Glass always sits over something living: the dawn gradient, the meadow, or scrolling text. Sheets and dialogs sit over a scrim: `--color-scrim` for dialogs and the picker, and the lighter `--color-scrim-soft` (8% / 25%) for the quiz feedback sheet so the answers stay readable.

Pencil cannot render refraction; the frames show blur, tint, rim and specular. The real material comes from the APIs below.

### 5.3 Component → API map

| Design element | SwiftUI (iOS 26) |
|---|---|
| Toolbar buttons (`Nav/GlassButton`), streak chip | `.toolbar { ToolbarItem(placement: .topBarLeading / .topBarTrailing) { Button(…, systemImage:) } }`. The system draws the glass; no custom glass behind it |
| Large title "Today" → inline on scroll | `.navigationTitle("Today")` + `.navigationBarTitleDisplayMode(.large)` |
| Tab bar (`Nav/TabBar/*`) | `TabView { Tab("Today", systemImage: "sun.max", value: …) … }` with the system glass tab bar; `.tint(accent)` |
| Minimized tab bar (`Nav/TabBarMin/Today`) | `.tabBarMinimizeBehavior(.onScrollDown)` |
| Bottom accessory (`Nav/Accessory/*`) | `.tabViewBottomAccessory { ContinueLessonAccessory() }`; inside, read `@Environment(\.tabViewBottomAccessoryPlacement)`: `.expanded` shows the eyebrow + title, `.inline` shows the title only. No `.glassEffect` on its content (the system supplies the glass) |
| `Button/Prominent` | `.buttonStyle(.glassProminent)` + `.tint(accentFill)`; press response comes from the style |
| `Button/Glass` | `.buttonStyle(.glass)` |
| Feedback sheet | Custom view with `.glassEffect(.regular, in: .rect(cornerRadius: 28))`, in one `GlassEffectContainer` with the Check button (Morph A) |
| Speech bubble, toast | `.glassEffect(.regular, in: .capsule)` |
| Scroll edge under the bar | `.scrollEdgeEffectStyle(.soft, for: .top)` |
| Reduce Transparency | `@Environment(\.accessibilityReduceTransparency)`: replace every custom `.glassEffect` with `--color-card-surface` + 1 pt `--color-glass-stroke` + the scrim. The system bars adapt on their own |

Icons (lucide in the frames → SF Symbol in code): `sun` → `sun.max`, `book-open` → `book`, `settings` → `gearshape`, `map` → `map`, `flame` → `flame.fill`, `chevron-left` → `chevron.left`, `x` → `xmark`, `pencil` → `pencil`, `list` → `list.bullet`, `lock` → `lock.fill`, `check` → `checkmark`, `flag` → `flag.fill`, `circle-check` → `checkmark.circle.fill`, `circle-x` → `xmark.circle.fill`, `play` → `play.fill`, `sprout` → `leaf`, `info` → `info.circle`, `loader-circle` → `ProgressView()`, `hourglass` → `hourglass`, `circle-alert` → `exclamationmark.circle`. The Lamb tab uses `Icon/LambGlyph`, a custom template image (the lamb silhouette with a cut-out face), instead of `hare.fill`.

## 6. Navigation

Tabs: **Today** (`sun.max`, the path), **Bible** (`book`, the reader), **Lamb** (custom glyph, the companion), **Settings** (`gearshape`). This replaces the code's `Path` tab: the path catalogue is pushed from Today's leading toolbar button (`map`), and that needs a `MainTabView` change. Lessons are pushed from a node with a zoom transition. The quiz is presented full screen (`.fullScreenCover`; the code uses `.sheet`). Onboarding and the paywall are modal. Every tab frame highlights its own tab; pushed screens keep their tab highlighted.

## 7. Screens

### 7.1 The story every frame follows

A first-time user names the lamb **Barnaby** in onboarding (sample name only; the app stores whatever the user types in `Companion.name`, default "Lamb"). They continue with the free path.

- **Day 1, before the lesson:** streak 0, 0 of 7 lessons, lamb Stage 1 (0 XP): `Home_DailyPath`, `Path_*`, `Lesson_Reading`, `Quiz_*`.
- **Day 1 complete, both answers right:** +12 XP (`10 + 2`), 12 / 50 XP, streak 1: `Lesson_Complete`, `Home_Day1Done`, `Companion_Detail`. `Quiz_Wrong` and `Quiz_Q2_Wrong` are the alternate branch (that branch would earn +11 or +10).
- **After Day 5** (5 perfect days = 60 XP): Stage 2 "Lamb", 60 / 100 XP: `Motion_StageUp_*`.
- The paywall states are alternate branches of the onboarding paywall. `Paywall_Restored` is a returning purchaser; `Settings` shows the free story ("Not active").

### 7.2 Rules for the implementer

1. **Path unlock (a design addition):** a node is current when it is the first lesson without `LessonProgress` (the code's `nextLesson`), done when it has progress, and locked otherwise. `PathListView` does not gate lessons today; add `isUnlocked = lesson.dayIndex <= nextLesson.dayIndex`.
2. **Quiz progress:** `progress = answeredCount / quiz.count`. It shows 0% on unanswered and selected, and moves to 50% when Check is tapped on question 1.
3. **Feedback content:** title ("Correct!" / "Keep going! You're learning."), then `explain` when it is non-null. The wrong sheet also says "Answer: {correct choice}.". Always show one verse: the lesson's first verse whose text contains the correct choice (case-insensitive), else `lesson.verseRefs[0]`. `Quiz_Q2_Wrong` proves the null-`explain` case: `day1-q2` → Genesis 1:3.
4. **Feedback sheet:** glass, corner 28, inset 8 pt from the screen edges, a 56 pt lamb avatar (Happy or Encouraging), Continue inside the sheet.
5. **Reward:** `+{10 + score} XP`, streak from `StreakState.current`, the XP bar to the next multiple of 50, and the "N XP to Stage k" remainder.
6. **Stages:** 1 Newborn (0–49), 2 Lamb (50–99), 3 Young sheep (100–149), 4 Yearling (150–199), 5 Grown sheep (200+). The same names are used everywhere.
7. **Paywall:** prices come from `Product.displayPrice`. `$29.99/year` and `$4.99/month` in the frames are placeholders, tagged on screen. The disclosure under the plans: "Free for 7 days, then {price}/year. Auto-renews until cancelled. Cancel anytime in Settings › Apple ID at least 24 hours before the trial ends." Purchasing, pending (Ask to Buy), failed ("You haven't been charged.") and restored are glass dialogs over the dimmed paywall.
8. **Bible sample gaps:** the bundle has Genesis 1:1–5, 26, 27, 31. After verse 5 the reader shows "Verses 6–25 aren't in this sample", and a quiet footer counts the sample's verses.

### 7.3 Frames (*generated*)

<!-- gen:frames -->
86 top-level frames (43 screens × light/dark), 728 library instances in the file.

| Screen | Size | Instances per frame | Exports |
|---|---|---|---|
| `Mascot_System` | 1240×1330 | 7 | [Light](exports/Mascot_System_Light.png) · [Dark](exports/Mascot_System_Dark.png) |
| `Home_DailyPath` | 402×874 | 13 | [Light](exports/Home_DailyPath_Light.png) · [Dark](exports/Home_DailyPath_Dark.png) |
| `Home_Scrolled` | 402×874 | 10 | [Light](exports/Home_Scrolled_Light.png) · [Dark](exports/Home_Scrolled_Dark.png) |
| `Lesson_Reading` | 402×874 | 6 | [Light](exports/Lesson_Reading_Light.png) · [Dark](exports/Lesson_Reading_Dark.png) |
| `Settings` | 402×874 | 9 | [Light](exports/Settings_Light.png) · [Dark](exports/Settings_Dark.png) |
| `Onboarding_BuildingPlan` | 402×874 | 5 | [Light](exports/Onboarding_BuildingPlan_Light.png) · [Dark](exports/Onboarding_BuildingPlan_Dark.png) |
| `Onboarding_NameLamb` | 402×874 | 5 | [Light](exports/Onboarding_NameLamb_Light.png) · [Dark](exports/Onboarding_NameLamb_Dark.png) |
| `Quiz_Unanswered` | 402×874 | 10 | [Light](exports/Quiz_Unanswered_Light.png) · [Dark](exports/Quiz_Unanswered_Dark.png) |
| `Quiz_Selected` | 402×874 | 10 | [Light](exports/Quiz_Selected_Light.png) · [Dark](exports/Quiz_Selected_Dark.png) |
| `Quiz_Correct` | 402×874 | 9 | [Light](exports/Quiz_Correct_Light.png) · [Dark](exports/Quiz_Correct_Dark.png) |
| `Quiz_Wrong` | 402×874 | 9 | [Light](exports/Quiz_Wrong_Light.png) · [Dark](exports/Quiz_Wrong_Dark.png) |
| `Quiz_Q2_Wrong` | 402×874 | 9 | [Light](exports/Quiz_Q2_Wrong_Light.png) · [Dark](exports/Quiz_Q2_Wrong_Dark.png) |
| `Settings_RestoreResult` | 402×874 | 9 | [Light](exports/Settings_RestoreResult_Light.png) · [Dark](exports/Settings_RestoreResult_Dark.png) |
| `Accessibility_AX3` | 402×874 | 5 | [Light](exports/Accessibility_AX3_Light.png) · [Dark](exports/Accessibility_AX3_Dark.png) |
| `Motion_QuizMorph_Start` | 402×874 | 10 | [Light](exports/Motion_QuizMorph_Start_Light.png) · [Dark](exports/Motion_QuizMorph_Start_Dark.png) |
| `Motion_QuizMorph_End` | 402×874 | 9 | [Light](exports/Motion_QuizMorph_End_Light.png) · [Dark](exports/Motion_QuizMorph_End_Dark.png) |
| `Motion_Accessory_Expanded` | 402×874 | 13 | [Light](exports/Motion_Accessory_Expanded_Light.png) · [Dark](exports/Motion_Accessory_Expanded_Dark.png) |
| `Motion_Accessory_Inline` | 402×874 | 10 | [Light](exports/Motion_Accessory_Inline_Light.png) · [Dark](exports/Motion_Accessory_Inline_Dark.png) |
| `Motion_PathZoom_Start` | 402×874 | 13 | [Light](exports/Motion_PathZoom_Start_Light.png) · [Dark](exports/Motion_PathZoom_Start_Dark.png) |
| `Motion_PathZoom_Mid` | 402×874 | 13 | [Light](exports/Motion_PathZoom_Mid_Light.png) · [Dark](exports/Motion_PathZoom_Mid_Dark.png) |
| `Motion_PathZoom_End` | 402×874 | 6 | [Light](exports/Motion_PathZoom_End_Light.png) · [Dark](exports/Motion_PathZoom_End_Dark.png) |
| `Motion_StageUp_End` | 402×874 | 5 | [Light](exports/Motion_StageUp_End_Light.png) · [Dark](exports/Motion_StageUp_End_Dark.png) |
| `Motion_Mascot` | 1240×1380 | 19 | [Light](exports/Motion_Mascot_Light.png) · [Dark](exports/Motion_Mascot_Dark.png) |
| `Lesson_Complete` | 402×874 | 7 | [Light](exports/Lesson_Complete_Light.png) · [Dark](exports/Lesson_Complete_Dark.png) |
| `Motion_StageUp_Start` | 402×874 | 6 | [Light](exports/Motion_StageUp_Start_Light.png) · [Dark](exports/Motion_StageUp_Start_Dark.png) |
| `Onboarding_Welcome` | 402×874 | 5 | [Light](exports/Onboarding_Welcome_Light.png) · [Dark](exports/Onboarding_Welcome_Dark.png) |
| `Onboarding_Goal` | 402×874 | 9 | [Light](exports/Onboarding_Goal_Light.png) · [Dark](exports/Onboarding_Goal_Dark.png) |
| `Onboarding_Experience` | 402×874 | 8 | [Light](exports/Onboarding_Experience_Light.png) · [Dark](exports/Onboarding_Experience_Dark.png) |
| `Onboarding_Pace` | 402×874 | 5 | [Light](exports/Onboarding_Pace_Light.png) · [Dark](exports/Onboarding_Pace_Dark.png) |
| `Companion_Detail` | 402×874 | 11 | [Light](exports/Companion_Detail_Light.png) · [Dark](exports/Companion_Detail_Dark.png) |
| `Bible_Reader` | 402×874 | 4 | [Light](exports/Bible_Reader_Light.png) · [Dark](exports/Bible_Reader_Dark.png) |
| `Paywall_Trial` | 402×874 | 9 | [Light](exports/Paywall_Trial_Light.png) · [Dark](exports/Paywall_Trial_Dark.png) |
| `Paywall_Purchasing` | 402×874 | 7 | [Light](exports/Paywall_Purchasing_Light.png) · [Dark](exports/Paywall_Purchasing_Dark.png) |
| `Paywall_Pending` | 402×874 | 8 | [Light](exports/Paywall_Pending_Light.png) · [Dark](exports/Paywall_Pending_Dark.png) |
| `Paywall_Failed` | 402×874 | 9 | [Light](exports/Paywall_Failed_Light.png) · [Dark](exports/Paywall_Failed_Dark.png) |
| `Paywall_Restored` | 402×874 | 9 | [Light](exports/Paywall_Restored_Light.png) · [Dark](exports/Paywall_Restored_Dark.png) |
| `Motion_QuizMorph_Mid` | 402×874 | 9 | [Light](exports/Motion_QuizMorph_Mid_Light.png) · [Dark](exports/Motion_QuizMorph_Mid_Dark.png) |
| `Path_Overview` | 402×874 | 7 | [Light](exports/Path_Overview_Light.png) · [Dark](exports/Path_Overview_Dark.png) |
| `Accessibility_AX3_QuizWrong` | 402×874 | 11 | [Light](exports/Accessibility_AX3_QuizWrong_Light.png) · [Dark](exports/Accessibility_AX3_QuizWrong_Dark.png) |
| `Bible_Picker` | 402×874 | 4 | [Light](exports/Bible_Picker_Light.png) · [Dark](exports/Bible_Picker_Dark.png) |
| `Home_Day1Done` | 402×874 | 13 | [Light](exports/Home_Day1Done_Light.png) · [Dark](exports/Home_Day1Done_Dark.png) |
| `Path_Lessons` | 402×874 | 4 | [Light](exports/Path_Lessons_Light.png) · [Dark](exports/Path_Lessons_Dark.png) |
| `Brand_System` | 1240×700 | 5 | [Light](exports/Brand_System_Light.png) · [Dark](exports/Brand_System_Dark.png) |
<!-- /gen:frames -->

Notes per screen:
- **Home_DailyPath:** an S-curve trail (28 pt stroke with a 1 pt edge) through three gradient vector hills. Nodes are at x 306 / 201 / 96 with a 112 pt pitch. The 88 pt lamb stands beside the current node with a glass bubble. There is no header card: the bottom accessory is the call to action. Days 5–6 sit under the accessory and tab bar.
- **Home_Scrolled:** scrolled 502 pt. Day 4 and the hill crest pass under the collapsed inline "Today" bar through a 24 pt blur band with a soft fade. The tab bar is minimized and the accessory is inline. Below Day 7 the path ends with its title.
- **Lesson_Reading / Bible_*:** no lamb. Serif verse text; the reader keeps verse numbers in accent.
- **Accessibility_AX3:** every text level at AX3 (caption 32, body 40, title1 44, the button label at 40, the toolbar title at 28); verse text at 40. **Accessibility_AX3_QuizWrong:** the feedback sheet at a large detent with AX3 text, the choices behind it.
- **Settings_RestoreResult:** "No purchases to restore" toast after Restore Purchases.

## 8. The lamb

### 8.1 Construction

Every lamb is a stack of filled vector paths on one shared per-stage viewBox, so an instance scales by its size. **The lamb is generated, not drawn by hand:** `python3 tools/brand/lambgen.py --style flock --out Shepherd/Resources/Content/lamb_variants.json` writes the app's JSON, and `tools/brand/apply_design.py lib` writes the same geometry into the 30 `Lamb/*` components (component ids are kept, so every instance stays linked). Change the lamb in the generator, never in the `.pen`.

- **Character:** a **black-faced lamb** (`--color-mascot-face` `#2A2526`), the way Suffolk lambs look. It reads as a sheep at 24 pt and holds contrast on every canvas without an outline. **There is no outline anywhere.**
- **Fleece cap:** five or six fleece circles over the forehead, unioned and smoothed: the signature shape. It is present at every stage (smaller at Stage 1).
- **Body:** a soft "bun" (a rounded rectangle plus three low top bumps), white fleece with a `--color-mascot-fleece-shade` crescent along the underside, and three faint curl marks (`FleeceCurls`). A small round tail.
- **Head:** an egg narrowing to the chin, overlapping the body's upper left, so the lamb faces three-quarters left. The head radius is 16% larger than the body proportions would suggest, which keeps the face legible small.
- **Ears:** long rounded teardrops held near horizontal, the far one behind the head, with pink inner ears. The angle depends on the expression.
- **Face:** **white sclera** (`--color-mascot-eye-white`) with dark pupils (`--color-mascot-features`) and catchlights. Happy, Celebrating and Sleepy eyes are cream arcs on the dark face. The nose is a soft pink rounded triangle (`--color-mascot-blush`); the mouth is a cream "w", or open in `--color-mascot-mouth` with a tongue. Blush cheeks at 70%.
- **Legs:** capsules in `--color-mascot-legs` (the face colour), with the far legs darker and hoof caps in `--color-mascot-hoof`. A ground shadow.
- **Palette:** fixed fills in both themes; only the shadow strengthens in dark. The bandana follows `--color-accent-fill`, and the bell and crown centres follow `--color-gold-fill`.

### 8.2 Stages and expressions

| Stage | XP | Display height | Pose | Adds |
|---|---|---|---|---|
| 1 Newborn | 0–49 | 64 pt | lying, hooves tucked, bigger eyes, ears droop more | small fleece cap |
| 2 Lamb | 50–99 | 80 pt | sitting, front legs show | fleece cap |
| 3 Young sheep | 100–149 | 96 pt | standing on four legs | taller cap, ultramarine bandana |
| 4 Yearling | 150–199 | 108 pt | standing, fuller fleece, longer legs | sunflower bell on the bandana knot |
| 5 Grown sheep | 200+ | 120 pt | standing, the fullest fleece | crown of five pink meadow flowers with sunflower centres (no halo, no laurel) |

Expressions (only eyes, mouth, ears and pose change):
- **Idle:** open eyes, cream "w" mouth, ears slightly drooped.
- **Happy:** cream ^ ^ eyes, open mouth with tongue, ears lifted, body raised 3.
- **Encouraging:** head tilted 10° clockwise, eyes looking up-left, small smile, one ear raised.
- **Celebrating:** closed-arc eyes, open mouth, front legs lifted (a whole-body hop at Stage 1), three sunflower four-point sparkles.
- **Sleepy:** eyes as closed arcs, ears drooping 35°, the lying pose, a vector "z z".
- **Hello:** the near front leg bends up beside the chin and waves, with two small motion arcs; ears perked, small open mouth.

`Mascot_System` shows all 30 variants, the size check (24 / 56 / 88 / 180 pt and the 24 pt tab glyph) and the palette.

### 8.3 Where it appears

| Placement | Variant and size |
|---|---|
| Welcome, Name your lamb | Stage 1 Hello, 140 pt, on a hill vignette |
| Onboarding questions, quiz before answering | Stage 1 Idle peeking bottom-left (72 / 56 pt) |
| Building plan | Stage 1 Happy, 120 pt |
| Today | Stage 1 Idle, 88 pt, beside the current node, with a glass bubble |
| Quiz feedback | 56 pt avatar: Happy (correct) or Encouraging (wrong) |
| Lesson complete | Stage 1 Celebrating, 160 pt, on a hill vignette |
| Companion | Stage 1 Idle hero (150 pt display height; a lying Newborn is wider than tall, about 330 × 165 pt), plus five 52 pt stage avatars |
| Paywall | 72 pt Happy avatar |
| Lesson reading, Bible reader | **never** |

### 8.4 Voice

The lamb is a humble study companion walking the path with you: it cheers small steps and never speaks as an authority on Scripture. Sample lines:

1. "Ready for Day 1?" (Home, first launch)
2. "1 day down!" (Home after Day 1)
3. "Keep going! You're learning." (wrong answer)
4. "Correct!" (right answer; the verse does the teaching)
5. "Rest well. Tomorrow's path will be waiting." (Sleepy, evening)
6. "No rush. Five quiet minutes is enough." (a gentle habit nudge)

## 9. Motion

Calm and short: soft springs, no confetti, nothing moves while scripture is on screen. SwiftUI only, with no Lottie and nothing fetched from the network. One spring for all glass morphs: `.spring(duration: 0.35, bounce: 0.15)`.

| # | Animation | Trigger | Duration | Curve | What moves | Haptic | Reduce Motion | Reduce Transparency |
|---|---|---|---|---|---|---|---|---|
| 1 | Lamb idle breathe | lamb on screen and idle (Today, Companion) | 3.2 s loop | `phaseAnimator([0, 1])`, `.easeInOut(duration: 1.6)` per phase | scaleY 1 → 1.02, anchored at the feet | none | static | n/a |
| 2 | Lamb blink | `keyframeAnimator`, random every 4–6 s | 0.18 s | linear keyframes | eye layer scaleY 1 → 0.1 → 1 | none | static | n/a |
| 3 | Happy hop | `isCorrect` becomes true on Check | 0.15 s up + 0.2 s down | cubic up, `.snappy(duration: 0.2)` down | y 0 → −12 → 0; land squash scaleY 0.94 | `.sensoryFeedback(.success, trigger:)` | expression swap with a 0.15 s crossfade | n/a |
| 4 | Encouraging tilt | wrong answer on Check | 0.4 s, then hold | `.spring(duration: 0.4, bounce: 0.2)` | `.rotationEffect` 0 → 10° | `.sensoryFeedback(.warning, trigger:)` | swap; never shake | n/a |
| 5 | Celebrate | Lesson Complete appears | 0.6 s | hop ×2; sparkles staggered 0.08 s | sparkles scale 0 → 1 → 0 | `.success` | static celebrating pose, sparkles shown statically | n/a |
| 6 | Stage-up | `stage` increases after `addXP` | ≈ 0.8 s | `.spring(duration: 0.5, bounce: 0.25)` for the new stage | old stage 1 → 1.08 and fades; new stage 0.9 → 1; one ring ripple | `.impact(weight: .medium)` | 0.25 s crossfade | ring drawn solid |
| 7 | Morph A: Check → feedback sheet | Check tapped | 0.35 s | `.spring(duration: 0.35, bounce: 0.15)` | Check capsule grows into the sheet: `GlassEffectContainer` + `.glassEffectID("quiz_action", in: ns)` | via 3 / 4 | crossfade | opaque card + 1 pt border + scrim |
| 8 | Morph B: accessory expanded ↔ inline | scroll down / up on Today | system | system | tab bar minimizes to a circle; the accessory moves inline beside it (`.tabBarMinimizeBehavior(.onScrollDown)`); content adapts via `tabViewBottomAccessoryPlacement` | none | system | system |
| 9 | Morph C: node → lesson | node tapped | system | system | `.matchedTransitionSource(id: lesson.id, in: ns)` on the node, `.navigationTransition(.zoom(sourceID: lesson.id, in: ns))` on `LessonView` | none | system crossfade | system |
| 10 | Check button press | press | system | system | `.buttonStyle(.glassProminent)` supplies the interactive press; no custom scale | none | system | system |
| 11 | Streak +1 | `markCompleted` | ≈ 0.3 s | default | number `.contentTransition(.numericText())`; flame `.symbolEffect(.bounce, value:)` | `.impact(weight: .light)` | numericText only | n/a |
| 12 | XP fill | reward card appears | 0.6 s | `.spring(duration: 0.6, bounce: 0.1)` | bar width | none | instant | n/a |
| 13 | Node unlock | the next lesson becomes current | 0.6 s | `.easeOut` | lock `.symbolEffect(.disappear)`; fill crossfades to ultramarine; one ring ripple, radius 36 → 52 pt, opacity 0.8 → 0 | none | crossfade | n/a |
| 14 | Scroll edge | scrolling under the bars | system | system | `.scrollEdgeEffectStyle(.soft, for: .top)`; nothing custom | none | system | system |

Frames: `Motion_QuizMorph_Start/Mid/End` (Morph A: the real quiz, all four choices; the mid frame is the Check capsule stretched to about 60% of the sheet with the label crossfading, and the end frame is identical to `Quiz_Correct`). `Motion_Accessory_Expanded/Inline` (Morph B = Home at rest / scrolled). `Motion_PathZoom_Start/Mid/End` (Morph C). `Motion_StageUp_Start/End` (row 6). `Motion_Mascot` (keyframes for rows 1–6).

```swift
// Morph A
@Namespace private var ns
GlassEffectContainer(spacing: 16) {
    if let result {
        FeedbackSheet(result: result)
            .glassEffect(.regular, in: .rect(cornerRadius: 28))
            .glassEffectID("quiz_action", in: ns)
    } else {
        Button("Check") { withAnimation(.spring(duration: 0.35, bounce: 0.15)) { result = check() } }
            .buttonStyle(.glassProminent)
            .glassEffectID("quiz_action", in: ns)
            .disabled(selected == nil)
    }
}

// Morph B
TabView { … }
    .tabBarMinimizeBehavior(.onScrollDown)
    .tabViewBottomAccessory { ContinueLessonAccessory() }   // reads \.tabViewBottomAccessoryPlacement

// Morph C
NodeView(lesson).matchedTransitionSource(id: lesson.id, in: ns)
LessonView(lesson: lesson).navigationTransition(.zoom(sourceID: lesson.id, in: ns))

// Lamb breathe (phaseAnimator already loops; no repeatForever)
LambView(stage:, expression: .idle)
    .phaseAnimator([0.0, 1.0]) { lamb, p in lamb.scaleEffect(x: 1, y: 1 + 0.02 * p, anchor: .bottom) }
        animation: { _ in .easeInOut(duration: 1.6) }

// Happy hop
LambView(stage:, expression: .happy)
    .keyframeAnimator(initialValue: Hop(), trigger: correctCount) { lamb, v in
        lamb.offset(y: v.y).scaleEffect(x: 1, y: v.squash, anchor: .bottom)
    } keyframes: { _ in
        KeyframeTrack(\.y) { CubicKeyframe(-12, duration: 0.15); SpringKeyframe(0, duration: 0.2, spring: .snappy) }
        KeyframeTrack(\.squash) { LinearKeyframe(1, duration: 0.33); LinearKeyframe(0.94, duration: 0.06); LinearKeyframe(1, duration: 0.1) }
    }
    .sensoryFeedback(.success, trigger: correctCount)
```

Every motion checks `@Environment(\.accessibilityReduceMotion)`, and every custom glass checks `\.accessibilityReduceTransparency`, as the table says.

## 10. Accessibility

- Contrast: 0 WCAG AA failures across every text pair in both themes (gate output in the PR).
- Dynamic Type: the sizes in section 4 map to the system styles. The two AX3 frames show the largest accessibility size, with text wrapping and buttons growing.
- Tap targets: toolbar buttons, chips and the tab bar items are 44 pt or more; rows are 52–60 pt; primary buttons are 56 pt.
- Reduce Transparency and Reduce Motion: section 5.3 and the motion table.

## 11. Gates

Run from the repo root; the outputs are pasted in the PR.

- `pen-audit.py design/shepherd.lib.pen design/screens/shepherd.pen`: library link ok, hex 0, dangling 0.
- `pen-layout-check.js` on the screens file: no clipped or overlapping text.
- `python3 tools/brand/tokens.py check flock`: every token pair (text at 4.5:1, icon tints and the current node at 3:1), light and dark, 0 failures.
- The export gate: no `_Light.png` byte-identical to its `_Dark.png`, and no black export.
- The reviewer's `sb_truth_probe.py`, `sb_chrome_probe.py` and `sb_contrast.py`, plus ref-aware variants of the truth and chrome probes. The variants expand library instances, so text and glass inside components are checked too. They are kept outside git, as the reviewer's probes are.

## 12. Known limits

- Fonts are render proxies (section 3).
- Pencil shows glass as blur, tint, rim and specular, without refraction.
- The tinted and clear app-icon appearances are generated images, so they are not drawn as frames (see `docs/brand/icon_sheet.png`).
- The motion frames are still keyframes; the timing lives in section 9.
