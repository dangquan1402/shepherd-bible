# Pasture — iOS 26 Liquid Glass Design Research

> **Renamed 2026-10-06: Shepherd → Pasture.** A naming scan found an existing App Store app, "Shepherd: Spiritual Bible BFF" (id 6745461941), with a lamb mascot and Duolingo-style Bible paths. The App Store name is now "Pasture: Daily Bible Path". The lamb, the Flock palette and the icon art are unchanged. Only the name and the wordmark (`pasture`, same Baloo 2 ExtraBold outline) changed. The research below was done under the old name.

This document establishes the empirical research foundation for the Pasture (formerly Shepherd) iOS 26 "Liquid Glass" redesign, conducted in accordance with the `refero-design` methodology. Every aesthetic, structural, and behavioral choice traces directly to live Refero MCP research, the sister app quality rubric, or Apple's official iOS 26 Liquid Glass specification.

---

## 1. Research Synthesis

### 1.1 Visual Direction & Taste (Refero Styles)

| Style | Refero ID / URL | What We Take | What We Reject |
|:---|:---|:---|:---|
| **mymind** | `3473a05f-d9c9-4b61-ba93-6c5569afb103`<br>https://mymind.com | Sunlit, airy atmosphere; warm private-archive feel; gentle unhurried rhythm; serene ambient light glow behind chrome; clean UI labels paired with dignified typography. | Pastel collage cards, oversized non-native marketing layout, decorative scattered browser artifacts. |
| **Alveos One** | `84380c51-bfa3-4343-91d0-c8fb997462aa`<br>https://www.alveoslabs.com | Calm, restorative mood; warm desaturated neutrals; creamy off-white morning canvas fading into clean surfaces; disciplined single primary action contrast. | Dark technical overlays, high-tech marketing renders, cold enterprise spacing. |
| **Alison Roman** | `0e9417ba-1c8d-421a-8880-047eff20959f`<br>https://www.alisoneroman.com | Tactile, bookish parchment aesthetic; dignified scripture presentation; dark ink typography carrying visual weight; generous breathing room. | Brown button fills, dense multi-column web blog grids, retro serif ornamentations. |
| **Medium** | `4784cf2e-58ed-4b0c-8e6d-8758f595d997`<br>https://medium.com | Clean reading hierarchy; text-first reverence; soft vellum warmth; understated functional chrome. | Paywall banner clutter, social follower counts, clunky web navigation. |

### 1.2 Concrete UI Patterns (Refero Screens)

| Domain | Refero Screen ID | Source App | Pattern Adapted |
|:---|:---|:---|:---|
| **Quiz & Lesson Feedback** | `0307c5b0-172f-457f-b1bf-dc897ebf13a6`<br>`474ff039-e63c-4fa6-866f-6ff1fda2a4dc` | Duolingo (iOS) | Stacked radio choice cards; instantaneous post-answer feedback sheet (green tint for correct, coral tint for incorrect); explanation citing the relevant verse reference; prominent primary action button. |
| **Daily Streak & Habit** | `0590e3dd-071b-4993-b48f-34a17594fe1b`<br>`24bd0c22-311a-43a6-a71d-3d22ab4cd321` | Foodvisor / Clearful (iOS) | Flame streak badge with day counter; 7-day horizontal weekday dot sequence; celebrating consistency without artificial gamification spam. |
| **Companion / Mascot** | `6d30579f-ae0d-40bc-b3fb-7e753f56cbc1`<br>`f4a0b4dd-b48e-4de9-a3e7-c7d234a50fdd` | Mindllama (iOS) | Cute vector sheep/lamb mascot inside circular badge; stage evolution based on XP; growth milestones directly tied to `Companion.xp` and `Companion.stage`. |
| **StoreKit 2 Trial Paywall** | `188237cf-f12f-44a0-899d-043fc3044666`<br>`2f5d1d88-a77e-49e8-bd5b-70e331f74da2` | Drops / The Athletic (iOS) | Vertical trial timeline (done step, Today, Day 5, Day 7); Pasture's Day 5 row is "Cancel anytime before Day 7" (no reminder promise, captain D3); Annual primary card ($29.99/yr placeholder) + Monthly option ($4.99/mo); auto-renew disclosure; Restore Purchases; Terms and Privacy links. |
| **Onboarding Questionnaire** | `b5494d57-8a09-4371-a3db-8dd105a3b094`<br>`c0b7caf1-89f3-4972-a3f5-096fff051026` | Todoist / How We Feel (iOS) | Clean single-column option cards with selection indicators; top progress bar; "Building your personal path" loading state with animated progress and summary of selected goals. |
| **Scripture & Bible Reader** | `4c8947a8-61fa-49f3-a7d8-5d65ac08bfad`<br>`d9a6a37d-2c7f-4f05-abfa-b317c513c797` | Apple Books / Fable (iOS) | Paper-like readability, generous 20pt side gutters, clear verse numbers in subtle secondary ink, translation badge ("WEB"), distraction-free typography. |

### 1.3 Journey Logic (Refero Flows)

- **Mindllama Flow 5489 (Premium Onboarding & Purchase):** Demonstrates the step progression from mascot introduction -> goal questionnaire -> plan construction animation -> soft trial paywall -> native purchase sheet -> success confirmation.
- **Drops Flow (Free Trial Activation):** Confirms that soft paywalls must allow easy dismissal ("Continue with free path") and clearly separate the trial period from the recurring billing date.

---


### 1.4 Mascot & Companion Systems (Refero & Industry Analysis)

| Companion | Source / App | What We Take | What We Reject |
|:---|:---|:---|:---|
| **Finch (Self-Care Pet)** | Finch (iOS) | Deep emotional bonding via naming ritual; developmental life stages driven by daily habit completion; soothing non-judgmental affirmations; patient presence when a streak lapses. | Extensive cosmetic wardrobe gamification; complex fantasy micro-currencies; cluttered bedroom UI. |
| **Headspace Characters** | Headspace (iOS) | Soft organic shapes; calm, grounded breathing rhythm; warm earthly tones; expressive eyes communicating mindfulness without speaking loud words. | Abstract amorphous blob geometry that lacks animal relatability. |
| **Duo (Duolingo)** | Duolingo (iOS) | Instantaneous emotional feedback on quiz events (glee on correct, sympathetic reaction on error); iconic silhouette recognizable at 24pt and 200pt. | Aggressive streak-threat guilt tactics; weeping/shaming mascot states; pushy high-pressure notifications. |
| **Calm (Breathing Companion)** | Calm (iOS) | Unhurried, reverent tempo; visual quietude; deliberate absence during deep meditation/reading sessions. | Pure inanimate gradient bubbles with zero narrative character connection. |

### 1.5 Fluid Motion & Material Dynamics (iOS 26 Liquid Glass)

| Interaction Pattern | Source / Spec | Implementation Mechanism | Purpose & Polish |
|:---|:---|:---|:---|
| **Glass Morphing Transitions** | Apple iOS 26 Specification & Cheatsheet | `GlassEffectContainer` + `glassEffectID` + `@Namespace` | Seamlessly transforms an inline action button into a rich feedback drawer without jarring layout pop. |
| **Interactive Glass Touch** | Apple HIG Materials | `.glassEffect(.regular.interactive())` | Real-time optical deflection and specular shimmer under user touch points and drag gestures. |
| **Living Companion Physics** | SwiftUI `KeyframeAnimator` & `PhaseAnimator` | Native 2D vector coordinate transforms | Gentle breathing squash-and-stretch (3.2s cycle); soft celebratory vertical hop (0.35s, 8pt apex); zero third-party Lottie runtime overhead. |

---

## 2. Reference Lock

```text
Primary reference/direction: Pastoral morning light (mymind warmth x Apple Books reading x Duolingo path),
  with a Mindllama-grade character at the centre.
Preserve:
  1. Parchment canvas (#FAF8F4 / #141716) with a dawn-sky gradient; illustrated meadow hills behind the Today path.
  2. Living Dawn Amber, text #9A5500 / #FBBF24, fill #B45309 / #A65500: actions, current node, progress, the lamb's ribbon.
  3. Liquid Glass only on chrome (toolbar buttons, streak chip, tab bar, accessory, sheets, dialogs, bubble, toast),
     never on glass, always over living content; content sits on opaque cards.
  4. The vector lamb: 5 stages (Newborn, Lamb, Young sheep, Yearling, Grown sheep; stage = 1 + xp/50) x 6 expressions.
  5. Verbatim WEB scripture and quiz text from the repo JSON.
Borrow only:
  - Duolingo: the path of 3D nodes as the screen (e3ac954a), a forgiving mascot line on a wrong answer (fd63609c).
  - Brilliant / Drops: the trial timeline with step 0 = what you already did.
  - Fable / Apple Books: a chrome-free serif reader with quiet verse numbers.
Role rules: green and red are quiz-correctness only; amber is never a background wash; glass is never content.
Media strategy: every illustration is a vector drawn in the .pen (lamb, hills, trail, vignettes); no bitmaps.
Reject: generic blue accents, emoji mascots, halos or laurels (authority signals), confetti, streak guilt,
  invented paths or numbers, glass-on-glass toolbars.
```

Mascot rules: the silhouette (scalloped fleece + hanging ears + dark legs) must read as a lamb at 24 pt. Fixed palette in both themes (fleece #FFF8EC, shade #E9DCC6, face #F4E3CC, features #3D312B, blush #EFA593); only the outline changes (#7A6655 / #FFF8EC 30%). The lamb is absent from Lesson reading and the Bible reader.

Motion rules: SwiftUI only. Glass morphs use one spring, `.spring(duration: 0.35, bounce: 0.15)`. Morph A = Check → feedback sheet (`GlassEffectContainer` + `glassEffectID`); Morph B = system accessory expanded ↔ inline (`tabBarMinimizeBehavior`); Morph C = node → lesson zoom (`matchedTransitionSource` + `navigationTransition(.zoom)`). Every item has a Reduce Motion and a Reduce Transparency fallback (design/README.md §9).

---

## 3. Decision Ledger

| Decision | Category | Source / Evidence | Rationale |
|:---|:---|:---|:---|
| **Parchment & Twilight Canvas** | Palette | Refero `mymind` & `Alison Roman` | Evokes physical vellum and sacred manuscript warmth without yellow tinting; provides comfortable contrast in morning and evening reading. |
| **Still Waters Blue Accent (Superseded)** | Palette | Superseded in Fix Round 1 | Superseded by Living Dawn Amber (row below) to ensure ownable pastoral identity and eliminate generic blue. |
| **Golden Wool Companion / Streak Tone** | Palette | Refero `Foodvisor` & `Mindllama` | Golden sunrise tone (`#D98200` light, `#F5A623` dark) for streak flame and XP stars; warm and encouraging. |
| **Opaque Content Cards** | Elevation | iOS 26 HIG & Open Pool §6.3 Rule 3 | Body scripture and quiz choices must never sit on transparent glass; prevents refraction artifacts and maintains WCAG AAA contrast. |
| **Floating Glass Chrome** | Liquid Glass | iOS 26 Cheatsheet & WWDC 2025 | System toolbars (44 pt glass buttons, no capsule behind them), glass tab bar, accessory and sheets: 55% fill, 24 pt background blur, shadow, a solid token rim plus a top-lit gradient specular. |
| **Glass Tab Bar with Bottom Accessory** | Navigation | iOS 26 Cheatsheet `.tabViewBottomAccessory` | Floats "Continue Today's Lesson" directly above the glass tab bar, collapsing gracefully during scroll. |
| **Scrolled State Z-Order** | Hierarchy | GROL Review B2 & N2 | Content passes UNDER blurred glass chrome; top and bottom progressive gradient fades prevent text collision. |
| **Verbatim Content Grounding** | Truthfulness | Repo `paths.json` & `sample_bible.json` | Every verse text, reference, lesson title, quiz prompt, and choice is extracted verbatim from the repo files. |
| **StoreKit 2 Soft Paywall Specs** | Monetization | `StoreKitManager.swift` & Drops `188237cf` | 7-day free trial timeline, Annual primary ($29.99/yr placeholder price tag) + Monthly ($4.99/mo placeholder), auto-renew disclosure, restore purchases, terms, privacy. |
| **Vector Lamb Companion Stages** | Mascot | `UserModels.swift` (`Companion.stage = 1 + xp/50`) | Stage 1 (0-49 XP): Newborn, Stage 2 (50-99 XP): Lamb, Stage 3 (100-149 XP): Young sheep, Stage 4 (150-199 XP): Yearling, Stage 5 (200+ XP): Grown sheep. |
| **Mascot Sanctuary Policy** | Mascot / UX | Reverent scripture reading | The lamb never appears alongside Scripture text in Lesson Reading or Bible Reader; preserves devotional reverence. |
| **Non-Shaming Mistake Pose** | Mascot / Ethics | Refero Finch & Headspace | When a quiz answer is wrong, the lamb shows an encouraging head-tilt with a warm smile, never crying or scolding. |
| **Glass Morphing Container** | Motion / Glass | iOS 26 Cheatsheet §5.2 | `GlassEffectContainer` shares the material buffer during button-to-sheet expansion, eliminating flickering. |
| **Native Vector Animators** | Motion / Mascot | SwiftUI (`phaseAnimator`, `keyframeAnimator`, iOS 17+) | Breathe, blink, hop, tilt, celebrate and stage-up are transforms on the lamb's vector layers; offline, no third-party runtime. |
| **Living Dawn Amber Accent** | Palette | Psalm 119:105 ("Your word is a lamp") & Refero `Abide` | Replaces generic system blue with warm, ownable Living Dawn Amber (`#9A5500` light / `#FBBF24` dark; fill `#B45309` / `#A65500`); distinct from quiz correctness (green) and quiz error (red). |
| **Pastoral Meadow Landscape Canvas** | Canvas / Glass | Refero `Mindllama` & Open Pool §6.3 | Layered rolling meadow hills (`--color-meadow-sky`, `--color-meadow-hill-*`, `--color-meadow-path`) provide physical shapes and pastoral hues for Liquid Glass chrome to blur and refract. |
| **S-Curve Path & Mascot Placement** | Layout / Mascot | Refero Duolingo `e3ac954a` & Captain Mascot Steer | One 28 pt trail stroke through three gradient vector hills; nodes alternate x 306 / 201 / 96 at a 112 pt pitch; the Stage 1 lamb (88 pt) stands beside the current node with a glass bubble "Ready for Day 1?". |
| **Home Hero vs Bottom Accessory Resolution** | Architecture | iOS 26 `.tabViewBottomAccessory` spec | Retains the persistent thumb-friendly bottom accessory docked above the glass tab bar; eliminates duplicate in-page hero card to open full vertical space for the meadow trail. |
| **Scrolled-Under-Glass Visual Proof** | Liquid Glass | GROL Review B2 & sb-review M2 | `Home_Scrolled_*` is scrolled 502 pt: Day 4 and the hill crest pass under the collapsed inline "Today" bar through a 24 pt blur band with a soft fade; the tab bar is minimized and the accessory is inline. |
| **Pedagogical Quiz Progress & Feedback** | Quiz / Learning | Duolingo & Refero `Finch` | Replaces redundant "Question 1 of 2" text with an elegant learning progress bar in the toolbar; wrong-state feedback sheet is a true Liquid Glass drawer morphing from the check button, featuring Barnaby Encouraging, verbatim Genesis 1:1 [WEB] citation, and "Continue" CTA. |
| **Human-Readable Exports** | Build Hygiene | GROL Review m1 & fix-round-1 #6 | One `<Screen_State>_<Light/Dark>.png` per frame (84), listed in `index.tsv`; a gate fails if a Light export equals its Dark twin or an export is black. |

| **3D Path Nodes** | Layout / Craft | Refero Duolingo `e3ac954a-8bca-4077-800d-b05302bde64e` | Each node is a face over a deeper "lip" (amber / amber-subtle / wool-white), so the path reads as tappable stepping stones; the current node gets a white ring and an amber glow. |
| **Lamb Proportions** | Mascot | Refero Mindllama `d36f6e63-ad80-462e-bf8a-70c439892f36` | A big, soft head over a scalloped fleece cloud, two hanging ears and dark legs; built from vector unions so the 2 pt outline wraps only the silhouette. |
| **Forgiving Wrong-Answer Moment** | Quiz / Mascot | Refero Duolingo `fd63609c-9369-4141-a26e-4063165b243a` | The wrong sheet leads with the Encouraging lamb and "Keep going! You’re learning.", then the answer and the verse; no shake, no tears. |
| **Pre-Cut Lamb Avatars** | Craft | Layout gate (no clipped nodes) | 56 pt head-and-shoulders avatars are geometry pre-intersected with the circle, not clip masks, so every node stays inside its parent. |
| **Render-Proxy Fonts** | Typography | Pencil renderer limits | Inter stands in for SF Pro and Newsreader for New York in the frames; the app ships the system fonts. |
---

## 4. Anti-Averaging Quality Gates

To ensure the design maintains an A+ standard and avoids generic "AI slop":
1. **Not a generic ham-radio or SaaS template:** Pasture has its own pastoral, devotional identity—warm vellum, quiet wool, morning sun, and still waters.
2. **Sharp contrast boundaries:** Text-to-surface pairs strictly exceed WCAG AA (4.5:1 for body, 3.0:1 for large text).
3. **No hallucinated features:** Strictly conforms to `docs/PLAN.md` and `README.md` (no social feeds, no cloud sync, no push notifications beyond local reminders).
4. **Honest privacy guarantees:** On-device storage via SwiftData clearly communicated throughout onboarding and settings.

---

## 5. Brand redesign: Flock (2026-10)

The identity above (Living Dawn Amber on parchment, the outlined beige lamb) is superseded for colour, mascot, icon and logo. Layout, navigation, glass and motion decisions above still stand. Three directions were built on copies of these files (Dayspring, Flock, Still Waters; boards in `data/sb-brand/directions/`, outside the repo). The captain chose **Flock**, with these tweaks: fix the Hello pose, enlarge the Stage 5 crown, keep it devotional, and use sunflower only for reward.

### 5.1 References (Refero MCP, images inspected)

| Reference | Refero | What we take | What we reject |
|---|---|---|---|
| Duolingo | app 5; screens `23d2b4cd…` (launch), `248b5230…` (welcome), `630776f9…` (dark lesson) | The face *is* the mark; a flat two-tone character with no outline; a dark that is navy-teal, not black; a lowercase rounded wordmark | Streak guilt, a shouting green field everywhere |
| Mindllama | app 185; `6d30579f…` (splash), `d4abc9e9…` (home-screen icon) | The face fills the icon tile on one saturated field, so it reads at dock size | Rainbow accessories, the llama's busy fleece texture |
| Headspace | app 4; `e2bb322d…`, `12ac38cd…` | Flat geometric character, closed-eye smiles, one bold colour per moment | Abstract blobs with no animal |
| Calm | app 17; `508e96c8…` | A chromatic night (deep blue) with glass tinted by the hue under it | Photo backgrounds |
| Honk, OLIPOP styles | `856297f1…`, `7aec15c5…` | One saturated field plus chunky rounded type, with each token kept to its role | Retro-kitsch display faces |

Gaps: Refero has no Finch, Hallow, Glorify, Dwell, Abide or YouVersion, and no iOS 26-specific screens. Those references come from public knowledge of the apps: YouVersion's red-brown book, Hallow's gold on purple and Glorify's pastels are the icons Flock must not resemble.

### 5.2 Reference lock

```text
Primary: a mascot-led brand (Duolingo grammar) made devotional.
Preserve: the face-led mark and icon; a flat two-tone lamb with no outline; one action colour
  (ultramarine) and one joy colour (sunflower) with strict roles; a chromatic dark (midnight indigo);
  a lowercase rounded wordmark.
Borrow only: Mindllama's face-fills-the-tile icon; Calm's hue-tinted glass on a coloured night.
Role rules: ultramarine = actions, current node, progress, icon tints, bandana. Sunflower = XP, streak,
  sparkles, bell, crown centres, sunlit path; never routine chrome. Green and red = quiz correctness only.
Reject: beige-on-cream lamb, brown outlines, amber doing two jobs, near-black dark, rounded display type
  for titles (New York stays), any lamb on scripture screens.
```

### 5.3 Decision ledger

| Decision | Source | Why |
|---|---|---|
| Black-faced lamb with a fleece cap and white-sclera eyes | Duolingo (face as mark), Suffolk lamb morphology, captain pick | Reads as a sheep at 24 pt; holds contrast on any canvas without an outline; ownable |
| No outline; underside shade crescent and three curl marks | Headspace, Duolingo | Removes the clip-art look; the fleece reads as wool, not cloud |
| Ultramarine `#3D3AE8` fill, `#3431D6` text | Honk style (one saturated field), WCAG | Clean, never muddy; white label 4.5:1+; far from quiz green and red |
| Dark fill `#5E5CF2` | WCAG non-text 3:1 + label 4.5:1 window | The only band where the button label and the icon tint both pass on indigo surfaces |
| Sunflower `#FFC21A` for reward only | Captain tweak; Duolingo's gold for XP | Joy stays special; the app stays calm |
| Midnight indigo `#14122E` dark | Calm, Duolingo dark | Chromatic dark gives the glass depth; sunflower and ultramarine glow on it |
| App icon: the front face on an ultramarine gradient | Mindllama, Duolingo | Fills the tile; reads at 29 pt and in tinted and clear |
| Wordmark: Baloo 2 ExtraBold, lowercase, outlined | Duolingo wordmark; OFL licence | Friendly mascot voice; shipped as paths, so no font file |
| New York titles and verses kept; no lamb on scripture | Captain tweak ("devotional, not a kids' app") | The brand gets bolder; the reading stays reverent |
