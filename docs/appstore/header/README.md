# Product page header and search results assets

Pasture's iOS 27 App Store creative assets, uploaded by hand in App Store Connect
(version page, Product Page Information, "Header and Search Results" tab; there is no API for them).

| File | Placement | Size | Variant |
|---|---|---|---|
| `header-3840x1646.png` | Product page header (21:9) | 3840 x 1646 | `header-a`: the lamb on the meadow path, no text |
| `search-3840x2560.png` | Search results (3:2, the maximum size) | 3840 x 2560 | `search-b`: headline, lamb, real Today and lesson screens |
| `preview.png` | Contact sheet: both variants of each at 25% with Apple's safe area outlined, a 10% thumbnail and the safe-area crop | | |

Both are PNG, RGB with no alpha, with the macOS sRGB IEC61966-2.1 profile embedded.

## Regenerate

```sh
python3 -m venv /tmp/assets-venv && /tmp/assets-venv/bin/pip install pillow resvg_py uharfbuzz fonttools
/tmp/assets-venv/bin/python -I docs/appstore/header/build_assets.py --out <dir> [--guides]
```

The script writes `header-a`, `header-b`, `search-a` and `search-b` plus `preview.png`, and with `--guides` a copy of each with the
safe area drawn. Copy `header-a.png` and `search-b.png` over the two committed files. The output is byte-stable.
Everything comes from the repo: colours from `tools/brand/tokens.py` (direction `pasture`, light), the lamb from
`Shepherd/Resources/Content/lamb_variants.json` (stage 3, Happy), meadow shapes after `MeadowBackgroundView` and `HillVignetteShape`,
and the phones are cut from the committed goldie captures in `../screenshots/iphone-6.9` (real XCUITest screens, 9:41 status bar).
Text is New York Bold (the app's `.serif` headings) and SF Pro, read from `/System/Library/Fonts`, so it needs macOS.
If a screen changes, regenerate the goldie screenshots first (`../README.md`) and then this.

## Apple's rules used

- Sizes and formats: [Creative assets specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications/):
  header 21:9 3840 x 1646 (or 16:9 5244 x 2950, PNG only); search results 3:2 from 1920 x 1280 to 3840 x 2560 (or 16:9 5244 x 2950);
  .jpeg, .jpg or .png; "Images can't include alpha channels or transparencies."
- Safe area: measured from the "Art Safe Area" layer of Apple's own templates (the Photoshop `creative_assets-*-template-static.psd`
  files and `creative_assets-templates.sketch` agree):
  header x 1097-2743, y 493-1154 (1646 x 661, centred); search x 836-3004, y 765-1795 (2168 x 1030, centred).
  Every key element (the lamb; the headline, subline and lamb on the search asset) sits inside it; the rest is full-bleed backdrop
  that can be cropped. Apple does not publish where the icon, name and Get button sit over the header, so the header's lower third
  is plain meadow and the asset has no text. Check both in App Store Connect's Preview tool before submitting.
- [Asset best practices](https://developer.apple.com/app-store/asset-best-practices/): header "Focus on a single, clear idea" and
  "Design with a first-time visitor in mind"; search results "State the obvious" and "Showcase the firsthand experience"; text
  "a short phrase that enhances your visual rather than describes it"; focal point "within the center of your composition";
  no pricing, URLs, unverifiable claims, other platforms or Apple recognitions; 4+ and for a global audience.

## Why these variants

- Header: `header-a` (lamb alone on the path) over `header-b` (lamb beside a lesson node). It has one focal point, the lamb is whole in
  the safe-area crop and still readable at 10%, and it says "Pasture" without words. In `header-b` the node and the lamb compete.
- Search: `search-b` (headline, subline and lamb on the left, Today and lesson screens on the right) over `search-a` (one-line
  headline over three screens). The whole pitch (headline, a subline that states the purpose, and the lamb) sits inside the
  safe area, and the Today screen is 11% larger than in `search-a` and not covered. In `search-a` the three screens are too small
  to read at search-result size, the side screens are half covered, and the lamb falls outside the safe area.
- The headline repeats screenshot 1 ("A little Bible, every day"), with "every day" in evergreen; sunflower is used only for the
  joy sparkles, as in Lesson Complete.
