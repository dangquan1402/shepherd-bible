# Pasture (formerly Shepherd) — build plan

## Positioning
On-device Bible habit app: short daily lessons, streak + lamb companion, soft annual paywall.  
Differentiator vs Manna: no account, no trackers, no cloud AI as authority.

## Milestones

### M0 — Scaffold (this repo)
- [x] Models + sample content JSON
- [x] SwiftUI shell screens
- [x] StoreKit paywall stub
- [ ] Create Xcode project on Mac and wire target

### M1 — Core loop (week 1–2)
- [ ] Load Bible + lessons from bundle
- [ ] Complete one lesson → quiz → streak update
- [ ] Companion XP / stage
- [ ] SwiftData persistence across launches

### M2 — Onboarding + paywall (week 2–3)
- [ ] Full 5–7 question onboarding
- [ ] “Building your plan” animation
- [ ] StoreKit 2 products + 7-day trial configuration in App Store Connect
- [ ] Soft paywall (annual highlighted)

### M3 — Polish (week 3–4)
- [ ] Widgets (verse + streak)
- [ ] Notifications (local only)
- [ ] Full beginner path (7–30 days)
- [ ] App icon + lamb illustrations
- [ ] Privacy Nutrition Labels (Data Not Collected / on-device only)

### M4 — Ship
- [ ] TestFlight
- [ ] ASO keywords
- [ ] Privacy policy (on-device claim must be accurate)

## Data model
See `Shepherd/Models/`

## Content rules
- v1 text: KJV or WEB only
- Lessons: original copy or commissioned; not scraped from copyrighted study Bibles
- Study aids labeled as aids, not doctrine
