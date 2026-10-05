# Shepherd

Privacy-first Bible learning for iOS — Duolingo-style daily path, lamb companion, soft paywall.  
No account. No Meta SDK. Progress stays on device.

Inspired by market research on Bible Study – Manna (habit UX + mascot onboarding), rebuilt for an on-device / privacy brand.

## Product lock

- **Direction:** Manna-style + privacy (`manna-clone-privacy`)
- **Platform:** iOS 26+ (SwiftUI Liquid Glass + SwiftData + StoreKit 2)
- **Bible text (v1):** public-domain **World English Bible (WEB)** or **KJV** bundled offline
- **Monetization:** free daily path + reader; Premium via soft paywall (7-day trial, annual primary + monthly)

## Repo layout

```
Shepherd/           # Swift sources, theme, views, resources
  App/
  Models/
  Views/
  Services/
  Resources/
    Assets.xcassets/
    Content/
  Theme/
docs/PLAN.md        # Build plan & milestones
scripts/            # Content & asset helpers
project.yml         # XcodeGen project definition
Shepherd.storekit   # StoreKit test configuration
```

## Quick start

```bash
xcodegen && open Shepherd.xcodeproj
```

Bundle ID suggestion: `com.dangvietquan.shepherd` (change to yours).

## v1 scope

- Onboarding (mascot → quiz → plan → soft paywall)
- Daily lesson + quiz + streak
- Lamb companion (name + stages)
- Local SwiftData persistence
- StoreKit 2 paywall shell
- Sample 7-day beginner path + sample WEB verses

## License / content

- App code: your copyright
- Sample verses: public-domain WEB excerpts for scaffolding only — replace/expand with a full licensed or public-domain corpus before release
- Do not ship NIV/ESV/etc. without a proper license (e.g. API.Bible)

## Author

Quan Dang / dangvietquan — privacy-first indie iOS apps
