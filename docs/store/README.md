# App Store listing (en-US)

The texts in `en-US/` are what App Store Connect holds for Pasture 1.0 (app 6819303372), applied on 2026-10-08
and read back byte for byte. The name is `Pasture: Daily Bible Path`. The name, subtitle and keywords together
index about 30 words. Never repeat a word across the three fields, because a repeat indexes nothing new.

| File | Field | Limit | Now |
|---|---|---|---|
| `subtitle.txt` | Subtitle (indexed) | 30 chars | 29 |
| `keywords.txt` | Keyword field (indexed, hidden) | 100 bytes | 100 |
| `promotional.txt` | Promotional text (not indexed, editable without review) | 170 chars | 170 |
| `description.txt` | Description (not indexed) | 4000 chars | 3597 |

`check_listing.py` holds the same copy as Python constants. It fails on limits, repeated words, competitor brands, and
claims the app does not make (KJV/NIV, AI, chat, community, audio, outfits, "Shepherd"). If you edit the copy, edit
the constants there and run `python3 -I docs/store/check_listing.py docs/store/en-US`, which rewrites the four files.
Then apply with `asc --profile LittleRed localizations update` (see AGENTS.md for the asc rules).
Every feature the description names must exist in the code: Premium is only what `Shepherd/Services/Entitlements.swift` lists.

URL fields (en-US, set 2026-10-08): privacy policy `https://pasturebible.com/privacy/`, support `https://pasturebible.com/support/`,
marketing `https://pasturebible.com/`. The description's Terms and Privacy lines and `ShepherdConstants` still use the GitHub Pages URLs.
