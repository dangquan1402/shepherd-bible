# Shepherd — iOS 26 Liquid Glass Design Research

This document establishes the empirical research foundation for the Shepherd iOS 26 "Liquid Glass" redesign, conducted in accordance with the `refero-design` methodology. Every aesthetic, structural, and behavioral choice traces directly to live Refero MCP research, the sister app quality rubric, or Apple's official iOS 26 Liquid Glass specification.

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
| **StoreKit 2 Trial Paywall** | `188237cf-f12f-44a0-899d-043fc3044666`<br>`2f5d1d88-a77e-49e8-bd5b-70e331f74da2` | Drops / The Athletic (iOS) | 3-step vertical trial timeline ("Today: Full access", "Day 5: Trial reminder", "Day 7: Billing begins"); Annual primary card ($39.99/yr placeholder) + Monthly option ($4.99/mo); auto-renew disclosure; Restore Purchases; Terms and Privacy links. |
| **Onboarding Questionnaire** | `b5494d57-8a09-4371-a3db-8dd105a3b094`<br>`c0b7caf1-89f3-4972-a3f5-096fff051026` | Todoist / How We Feel (iOS) | Clean single-column option cards with selection indicators; top progress bar; "Building your personal path" loading state with animated progress and summary of selected goals. |
| **Scripture & Bible Reader** | `4c8947a8-61fa-49f3-a7d8-5d65ac08bfad`<br>`d9a6a37d-2c7f-4f05-abfa-b317c513c797` | Apple Books / Fable (iOS) | Paper-like readability, generous 20pt side gutters, clear verse numbers in subtle secondary ink, translation badge ("WEB"), distraction-free typography. |

### 1.3 Journey Logic (Refero Flows)

- **Mindllama Flow 5489 (Premium Onboarding & Purchase):** Demonstrates the step progression from mascot introduction -> goal questionnaire -> plan construction animation -> soft trial paywall -> native purchase sheet -> success confirmation.
- **Drops Flow (Free Trial Activation):** Confirms that soft paywalls must allow easy dismissal ("Continue with free path") and clearly separate the trial period from the recurring billing date.

---

## 2. Reference Lock

```text
Primary Reference: Pastoral Morning Light (mymind × Apple Books × Mindllama)
Visual Thesis: A sunlit, peaceful sanctuary for daily Scripture habit. Warm parchment and morning meadow tones beneath authentic Apple iOS 26 Liquid Glass chrome.

Traits to Preserve:
1. Warm parchment canvas (#FAF8F4 light, #141716 dark) with crisp opaque white cards (#FFFFFF light, #1D2220 dark).
2. Noble "Still Waters" lapis blue accent (#2860A8 light, #4A88D9 dark), inspired by Psalm 23:2, reserved exclusively for primary actions and path progression.
3. Liquid Glass strictly on floating chrome: Navigation bars, Glass Tab Bar, Bottom Accessories (`tabViewBottomAccessory`), and Sheets. Content stays anchored on solid cards.
4. Real vector lamb companion mascot progressing across 5 stages (Newborn, Sprout, Lamb, Yearling, Flock Leader), never emojis.
5. Verbatim Scripture and quiz content from bundled WEB and paths.json; zero invented text or metrics.

Borrow Only:
- Duolingo: Instant quiz feedback bottom drawer with verse explanation.
- Drops: 3-step vertical trial timeline on the paywall.
- Apple Books: Generous margins and verse typographic rhythm.

Explicit Rejects:
- No generic Tailwind palette (slate/sky/emerald).
- No green/red brand accents; green is strictly quiz-correct, red is strictly quiz-wrong.
- No AI buzzwords, no cloud accounts, no social leaderboards, no artificial streak multipliers.
- No glass-on-glass stacking; no glass behind dense multi-line reading text.
- No fake or hand-typed scripture.

Media Strategy:
- Mascot: High-craft vector illustration drawn in Pencil components for each of the 5 companion stages.
- Icons: Native SF Symbols / Lucide standard glyphs with verified rendering names (e.g. circle-check-big, flame, book-open, map-pin, sparkler).
```

---

## 3. Decision Ledger

| Decision | Category | Source / Evidence | Rationale |
|:---|:---|:---|:---|
| **Parchment & Twilight Canvas** | Palette | Refero `mymind` & `Alison Roman` | Evokes physical vellum and sacred manuscript warmth without yellow tinting; provides comfortable contrast in morning and evening reading. |
| **Still Waters Blue Accent** | Palette | Psalm 23:2 (`sample_bible.json`) & `ShepherdTheme.accent` | Blue represents guidance and peace; keeps brand distinct from quiz correctness (green) and streak fire (gold/amber). |
| **Golden Wool Companion / Streak Tone** | Palette | Refero `Foodvisor` & `Mindllama` | Golden sunrise tone (`#D98200` light, `#F5A623` dark) for streak flame and XP stars; warm and encouraging. |
| **Opaque Content Cards** | Elevation | iOS 26 HIG & Open Pool §6.3 Rule 3 | Body scripture and quiz choices must never sit on transparent glass; prevents refraction artifacts and maintains WCAG AAA contrast. |
| **Floating Glass Chrome** | Liquid Glass | iOS 26 Cheatsheet & WWDC 2025 | System toolbars, floating action pills, and glass tab bar with `.glassEffect(.regular)` and background blur (16pt radius) + specular rim. |
| **Glass Tab Bar with Bottom Accessory** | Navigation | iOS 26 Cheatsheet `.tabViewBottomAccessory` | Floats "Continue Today's Lesson" directly above the glass tab bar, collapsing gracefully during scroll. |
| **Scrolled State Z-Order** | Hierarchy | GROL Review B2 & N2 | Content passes UNDER blurred glass chrome; top and bottom progressive gradient fades prevent text collision. |
| **Verbatim Content Grounding** | Truthfulness | Repo `paths.json` & `sample_bible.json` | Every verse text, reference, lesson title, quiz prompt, and choice is extracted verbatim from the repo files. |
| **StoreKit 2 Soft Paywall Specs** | Monetization | `StoreKitManager.swift` & Drops `188237cf` | 7-day free trial timeline, Annual primary ($39.99/yr placeholder) + Monthly ($4.99/mo placeholder), auto-renew disclosure, restore purchases, terms, privacy. |
| **Vector Lamb Companion Stages** | Mascot | `UserModels.swift` (`Companion.stage = 1 + xp/50`) | Stage 1 (0-49 XP): Newborn, Stage 2 (50-99 XP): Sprout, Stage 3 (100-149 XP): Lamb, Stage 4 (150-199 XP): Yearling, Stage 5 (200+ XP): Flock Leader. |

---

## 4. Anti-Averaging Quality Gates

To ensure the design maintains an A+ standard and avoids generic "AI slop":
1. **Not a generic ham-radio or SaaS template:** Shepherd has its own pastoral, devotional identity—warm vellum, quiet wool, morning sun, and still waters.
2. **Sharp contrast boundaries:** Text-to-surface pairs strictly exceed WCAG AA (4.5:1 for body, 3.0:1 for large text).
3. **No hallucinated features:** Strictly conforms to `docs/PLAN.md` and `README.md` (no social feeds, no cloud sync, no push notifications beyond local reminders).
4. **Honest privacy guarantees:** On-device storage via SwiftData clearly communicated throughout onboarding and settings.
