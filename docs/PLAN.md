# Pasture (formerly Shepherd) — build plan

## Positioning
On-device Bible habit app: short daily lessons, streak + lamb companion, soft annual paywall.  
Differentiator vs Manna: no account, no trackers, no cloud AI as authority.

## Milestones

### M0 — Scaffold (this repo)
- [x] Models + sample content JSON
- [x] SwiftUI shell screens
- [x] StoreKit paywall stub
- [x] Create Xcode project on Mac and wire target (`project.yml` → `xcodegen`)

### M1 — Core loop (week 1–2)
- [x] Load Bible + lessons from bundle (`web.json`, `paths.json` via `ContentStore`)
- [x] Complete one lesson → quiz → streak update
- [x] Companion XP / stage
- [x] SwiftData persistence across launches

### M2 — Onboarding + paywall (week 2–3)
- [x] Full 5–7 question onboarding (goal, familiarity, pace, lamb name, reminder)
- [x] “Building your plan” animation (“Preparing your path…” step)
- [x] StoreKit 2 products + 7-day trial configuration in App Store Connect (group 22442787, both plans with a 1-week free trial; subscription metadata still to submit)
- [x] Soft paywall (annual highlighted)

### M3 — Polish (week 3–4)
- [ ] Widgets (verse + streak)
- [x] Notifications (local only): opt-in daily reminder, free (`DailyReminder`)
- [x] Full beginner path (7–30 days): First Steps, 30 lessons
- [x] App icon + lamb illustrations
- [ ] Privacy Nutrition Labels (Data Not Collected / on-device only)

### M4 — Ship
- [x] TestFlight (1.0.0 build 3 uploaded, `tools/archive.sh`)
- [x] ASO keywords (en-US keyword field set in App Store Connect)
- [ ] Privacy policy (on-device claim must be accurate): published, but its "does not send notifications" line needs the daily-reminder update

Post-1.0 backlog: GitHub issues [#10–#24](https://github.com/dangquan1402/shepherd-bible/issues) (#10, local daily reminders, ships in PR #9).

## Data model
See `Shepherd/Models/`

## Content rules
- v1 text: KJV or WEB only
- Lessons: original copy or commissioned; not scraped from copyrighted study Bibles
- Study aids labeled as aids, not doctrine
