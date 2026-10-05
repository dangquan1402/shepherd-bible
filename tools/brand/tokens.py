"""Brand colour tokens for the three Shepherd directions, plus a WCAG contrast gate.

Every colour variable in design/shepherd.lib.pen is defined here per direction as
(light, dark). Derived tokens (clear / veil variants) are computed from their base.

    python3 tools/brand/tokens.py check            # AA gate for all three directions
    python3 tools/brand/tokens.py check flock      # one direction
"""
from __future__ import annotations

import sys

# shared, theme-independent
FIXED = {
    "--color-on-accent": ("#FFFFFF", "#FFFFFF"),
    "--color-transparent": ("#00000000", "#00000000"),
    "--color-phone-island": ("#000000", "#000000"),
    "--color-phone-camera": ("#1A1A2E", "#1A1A2E"),
    "--color-phone-sensor": ("#111111", "#111111"),
    "--color-note": ("#6D28D9", "#C4B5FD"),
    "--color-note-subtle": ("#F1EAFE", "#2A2144"),
    "--color-mascot-catchlight": ("#FFFFFF", "#FFFFFF"),
    "--color-glass-spec-mid": ("#FFFFFF00", "#FFFFFF00"),
}

DIRECTIONS = {
    # ------------------------------------------------------------------ A
    "dayspring": {
        "name": "Dayspring",
        "idea": "The warm identity, purified: persimmon light on clean cream by day, a deep pine evening by night.",
        "tokens": {
            "--color-canvas-bg": ("#FFFAF3", "#0E2421"),
            "--color-card-surface": ("#FFFFFF", "#15302C"),
            "--color-surface-sunken": ("#F7EEE2", "#1B3A35"),
            "--color-surface-border": ("#EEDFCB", "#26493F"),
            "--color-text-primary": ("#2A1B14", "#F6F2EA"),
            "--color-text-secondary": ("#68524A", "#BCCBC4"),
            "--color-text-tertiary": ("#7A6359", "#9AB0A7"),
            "--color-accent": ("#B23A0C", "#FFA270"),
            "--color-accent-fill": ("#C2410C", "#CE4B10"),
            "--color-accent-subtle": ("#FFE9D9", "#3A2E22"),
            "--color-accent-fill-deep": ("#8A2C05", "#7F2A06"),
            "--color-accent-subtle-deep": ("#F4C8A6", "#4A3826"),
            "--color-gold": ("#8A5300", "#FFCB5C"),
            "--color-gold-fill": ("#F2A818", "#F2A818"),
            "--color-gold-subtle": ("#FFF3D6", "#33321D"),
            "--color-node-current-ring": ("#FFFFFF", "#FFF4E6"),
            "--color-node-glow": ("#C2410C55", "#FFA27040"),
            "--color-node-locked": ("#FFFDF9", "#1D3E38"),
            "--color-node-locked-deep": ("#E8D7BF", "#10292A"),
            "--color-success": ("#137135", "#4ADE80"),
            "--color-success-subtle": ("#EAF7EE", "#173A26"),
            "--color-success-fill": ("#137135", "#15803D"),
            "--color-success-deep": ("#0D4F25", "#0E5A2B"),
            "--color-error": ("#B91C1C", "#FF8A8A"),
            "--color-error-subtle": ("#FDF0EF", "#3C1F1F"),
            "--color-glass-fill": ("#FFFFFF99", "#18352FA6"),
            "--color-glass-stroke": ("#E6D3BC", "#FFFFFF2E"),
            "--color-glass-specular": ("#FFFFFFE6", "#FFFFFF4D"),
            "--color-glass-spec-top": ("#FFFFFFE6", "#FFFFFF73"),
            "--color-glass-spec-bottom": ("#9A6B4A4D", "#FFFFFF1F"),
            "--color-glass-inner-hi": ("#FFFFFFA6", "#FFFFFF40"),
            "--color-shadow-glass": ("#5A2E1414", "#00000040"),
            "--color-shadow-glass-heavy": ("#5A2E1426", "#00000073"),
            "--color-scrim": ("#2A1B1459", "#04100E99"),
            "--color-scrim-soft": ("#2A1B1414", "#04100E40"),
            "--color-tab-selection": ("#C2410C1A", "#FFFFFF24"),
            "--color-meadow-sky": ("#FFF1DE", "#0F2C33"),
            "--color-meadow-sky-bottom": ("#FFE6C9", "#12352F"),
            "--color-meadow-hill-distant": ("#DCEFC4", "#163F35"),
            "--color-meadow-hill-mid": ("#C9E7A8", "#1A4A3D"),
            "--color-meadow-hill-near": ("#B6DD8C", "#1F5545"),
            "--color-meadow-path": ("#F6E7CB", "#2F5247"),
            "--color-meadow-path-border": ("#E4CDA6", "#3F665A"),
            "--color-mascot-fleece": ("#FFFDF8", "#FFFDF8"),
            "--color-mascot-fleece-shade": ("#F0E2CB", "#F0E2CB"),
            "--color-mascot-face": ("#F7E3C8", "#F7E3C8"),
            "--color-mascot-features": ("#4A3428", "#4A3428"),
            "--color-mascot-legs": ("#4A3428", "#4A3428"),
            "--color-mascot-far-legs": ("#36251C", "#36251C"),
            "--color-mascot-hoof": ("#281A13", "#281A13"),
            "--color-mascot-blush": ("#F4A08C", "#F4A08C"),
            "--color-mascot-outline": ("#E3CBA6", "#E3CBA600"),
            "--color-mascot-shadow": ("#3A2A1A22", "#00000059"),
            "--color-mascot-tongue": ("#E8796B", "#E8796B"),
            "--color-mascot-bell": ("#E8A824", "#E8A824"),
            "--color-mascot-eye-white": ("#FFFFFF", "#FFFFFF"),
            "--color-mascot-mouth": ("#4A3428", "#4A3428"),
            "--color-mascot-flower": ("#FFFFFF", "#FFFFFF"),
            "--color-mascot-zz": ("#B39876", "#9AB0A7"),
        },
    },
    # ------------------------------------------------------------------ B
    "flock": {
        "name": "Flock",
        "idea": "A bold, mascot-led brand: ultramarine action, sunflower joy and a black-faced lamb you can spot from across a room.",
        "tokens": {
            "--color-canvas-bg": ("#FBFAFF", "#14122E"),
            "--color-card-surface": ("#FFFFFF", "#1E1B42"),
            "--color-surface-sunken": ("#F0EFFA", "#262351"),
            "--color-surface-border": ("#E1DFF2", "#322F63"),
            "--color-text-primary": ("#18163A", "#F6F5FF"),
            "--color-text-secondary": ("#4C4970", "#C2BFE6"),
            "--color-text-tertiary": ("#5F5C84", "#A19DCB"),
            "--color-accent": ("#3431D6", "#B3B2FF"),
            "--color-accent-fill": ("#3D3AE8", "#5E5CF2"),
            "--color-accent-subtle": ("#E9E9FF", "#2D2A66"),
            "--color-accent-fill-deep": ("#2421A8", "#2A27A6"),
            "--color-accent-subtle-deep": ("#C9C8FA", "#3B3880"),
            "--color-gold": ("#8A5200", "#FFD23F"),
            "--color-gold-fill": ("#FFC21A", "#FFC21A"),
            "--color-gold-subtle": ("#FFF5CF", "#3A3326"),
            "--color-node-current-ring": ("#FFFFFF", "#FFF7D6"),
            "--color-node-glow": ("#3D3AE855", "#FFD23F40"),
            "--color-node-locked": ("#FFFFFF", "#29265A"),
            "--color-node-locked-deep": ("#D9D7EE", "#151236"),
            "--color-success": ("#137135", "#4ADE80"),
            "--color-success-subtle": ("#EAF7EE", "#173528"),
            "--color-success-fill": ("#137135", "#15803D"),
            "--color-success-deep": ("#0D4F25", "#0E5A2B"),
            "--color-error": ("#B91C1C", "#FF8A8A"),
            "--color-error-subtle": ("#FDF0EF", "#3B1E33"),
            "--color-glass-fill": ("#FFFFFF94", "#221F4CA6"),
            "--color-glass-stroke": ("#D6D4EE", "#FFFFFF30"),
            "--color-glass-specular": ("#FFFFFFE6", "#FFFFFF4D"),
            "--color-glass-spec-top": ("#FFFFFFE6", "#FFFFFF80"),
            "--color-glass-spec-bottom": ("#4C49704D", "#FFFFFF1F"),
            "--color-glass-inner-hi": ("#FFFFFFA6", "#FFFFFF45"),
            "--color-shadow-glass": ("#18163A14", "#00000040"),
            "--color-shadow-glass-heavy": ("#18163A26", "#00000073"),
            "--color-scrim": ("#18163A59", "#07061899"),
            "--color-scrim-soft": ("#18163A14", "#07061840"),
            "--color-tab-selection": ("#3D3AE81A", "#FFFFFF24"),
            "--color-meadow-sky": ("#ECEEFF", "#1A1848"),
            "--color-meadow-sky-bottom": ("#FFF4D1", "#23205A"),
            "--color-meadow-hill-distant": ("#D2F0AE", "#1C3A4E"),
            "--color-meadow-hill-mid": ("#BCE890", "#204656"),
            "--color-meadow-hill-near": ("#A3DD72", "#25525F"),
            "--color-meadow-path": ("#FFF1BF", "#3A3772"),
            "--color-meadow-path-border": ("#F0D47E", "#4C4994"),
            "--color-mascot-fleece": ("#FFFFFF", "#FFFFFF"),
            "--color-mascot-fleece-shade": ("#ECE6DC", "#ECE6DC"),
            "--color-mascot-face": ("#2A2526", "#2A2526"),
            "--color-mascot-features": ("#141012", "#141012"),
            "--color-mascot-legs": ("#2A2526", "#2A2526"),
            "--color-mascot-far-legs": ("#1A1617", "#1A1617"),
            "--color-mascot-hoof": ("#100D0E", "#100D0E"),
            "--color-mascot-blush": ("#FF9EB1", "#FF9EB1"),
            "--color-mascot-outline": ("#2A252600", "#2A252600"),
            "--color-mascot-shadow": ("#18163A22", "#00000066"),
            "--color-mascot-tongue": ("#FF7D8F", "#FF7D8F"),
            "--color-mascot-bell": ("#FFC21A", "#FFC21A"),
            "--color-mascot-eye-white": ("#FFFFFF", "#FFFFFF"),
            "--color-mascot-mouth": ("#5B1E2E", "#5B1E2E"),
            "--color-mascot-flower": ("#FF9EB1", "#FF9EB1"),
            "--color-mascot-zz": ("#8C86B8", "#A19DCB"),
        },
    },
    # ------------------------------------------------------------------ C
    "still": {
        "name": "Still Waters",
        "idea": "Psalm 23 as a palette: mist and lake blue by day, a deep still lake at night, one candle of gold.",
        "tokens": {
            "--color-canvas-bg": ("#F4F6F5", "#0D1B26"),
            "--color-card-surface": ("#FFFFFF", "#142533"),
            "--color-surface-sunken": ("#EAEFEE", "#1A2F3F"),
            "--color-surface-border": ("#DAE2E0", "#24394B"),
            "--color-text-primary": ("#16212A", "#EEF3F6"),
            "--color-text-secondary": ("#44525C", "#B0BFC9"),
            "--color-text-tertiary": ("#5B6A74", "#8FA1AD"),
            "--color-accent": ("#245A8A", "#94C4F0"),
            "--color-accent-fill": ("#2C6597", "#2A76B8"),
            "--color-accent-subtle": ("#E1ECF6", "#1C3550"),
            "--color-accent-fill-deep": ("#1A4268", "#173C5E"),
            "--color-accent-subtle-deep": ("#B9D0E6", "#284766"),
            "--color-gold": ("#80601A", "#EBC872"),
            "--color-gold-fill": ("#D7A73E", "#D7A73E"),
            "--color-gold-subtle": ("#F7F0DE", "#2B2B22"),
            "--color-node-current-ring": ("#FFFFFF", "#F2F6F8"),
            "--color-node-glow": ("#2C659755", "#94C4F040"),
            "--color-node-locked": ("#FFFFFF", "#1B3242"),
            "--color-node-locked-deep": ("#D3DCDA", "#0A1620"),
            "--color-success": ("#137135", "#4ADE80"),
            "--color-success-subtle": ("#EAF6EE", "#16332A"),
            "--color-success-fill": ("#137135", "#15803D"),
            "--color-success-deep": ("#0D4F25", "#0E5A2B"),
            "--color-error": ("#B91C1C", "#FF8A8A"),
            "--color-error-subtle": ("#FCEFEF", "#3A1F27"),
            "--color-glass-fill": ("#FFFFFF94", "#16293AA6"),
            "--color-glass-stroke": ("#CFD9D7", "#FFFFFF2E"),
            "--color-glass-specular": ("#FFFFFFE6", "#FFFFFF4D"),
            "--color-glass-spec-top": ("#FFFFFFE6", "#FFFFFF73"),
            "--color-glass-spec-bottom": ("#4A59634D", "#FFFFFF1F"),
            "--color-glass-inner-hi": ("#FFFFFFA6", "#FFFFFF40"),
            "--color-shadow-glass": ("#16212A14", "#00000040"),
            "--color-shadow-glass-heavy": ("#16212A26", "#00000073"),
            "--color-scrim": ("#16212A59", "#040B1199"),
            "--color-scrim-soft": ("#16212A14", "#040B1140"),
            "--color-tab-selection": ("#2C65971A", "#FFFFFF24"),
            "--color-meadow-sky": ("#E7F0F4", "#10293A"),
            "--color-meadow-sky-bottom": ("#F5EFE3", "#13303C"),
            "--color-meadow-hill-distant": ("#D6E6DC", "#173B42"),
            "--color-meadow-hill-mid": ("#C3D9C9", "#1B4548"),
            "--color-meadow-hill-near": ("#AFCDB7", "#20504E"),
            "--color-meadow-path": ("#EEE8DC", "#2A4654"),
            "--color-meadow-path-border": ("#D8CDBB", "#385868"),
            "--color-mascot-fleece": ("#F6F1EA", "#F6F1EA"),
            "--color-mascot-fleece-shade": ("#E2D8CA", "#E2D8CA"),
            "--color-mascot-face": ("#E3D5C3", "#E3D5C3"),
            "--color-mascot-features": ("#2E2C33", "#2E2C33"),
            "--color-mascot-legs": ("#9C8F82", "#9C8F82"),
            "--color-mascot-far-legs": ("#8F857B", "#8F857B"),
            "--color-mascot-hoof": ("#6B625A", "#6B625A"),
            "--color-mascot-blush": ("#E9B7A8", "#E9B7A8"),
            "--color-mascot-outline": ("#CFC3B300", "#CFC3B300"),
            "--color-mascot-shadow": ("#1E2A3322", "#00000059"),
            "--color-mascot-tongue": ("#D98C84", "#D98C84"),
            "--color-mascot-bell": ("#C9A24A", "#C9A24A"),
            "--color-mascot-eye-white": ("#FFFFFF", "#FFFFFF"),
            "--color-mascot-mouth": ("#34333A", "#34333A"),
            "--color-mascot-flower": ("#FFFFFF", "#FFFFFF"),
            "--color-mascot-zz": ("#93A0AD", "#8FA1AD"),
        },
    },
}


def _derive(t):
    canvas, sky = t["--color-canvas-bg"], t["--color-meadow-sky"]
    t["--color-canvas-clear"] = (canvas[0] + "00", canvas[1] + "00")
    t["--color-canvas-veil"] = (canvas[0] + "B3", canvas[1] + "B3")
    t["--color-meadow-sky-clear"] = (sky[0] + "00", sky[1] + "00")
    t["--color-meadow-sky-veil"] = (sky[0] + "B3", sky[1] + "B3")
    return t


for _d in DIRECTIONS.values():
    _d["tokens"] = _derive({**FIXED, **_d["tokens"]})


def tokens(direction):
    return DIRECTIONS[direction]["tokens"]


# ---------------------------------------------------------------- contrast


def _rgba(h):
    h = h.lstrip("#")
    c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    a = int(h[6:8], 16) / 255 if len(h) == 8 else 1.0
    return c, a


def over(fg, bg):
    (f, a), (b, _) = _rgba(fg), _rgba(bg)
    return "#%02X%02X%02X" % tuple(round((f[i] * a + b[i] * (1 - a)) * 255) for i in range(3))


def lum(h):
    c, _ = _rgba(h)
    g = lambda x: x / 12.92 if x <= 0.03928 else ((x + 0.055) / 1.055) ** 2.4
    return 0.2126 * g(c[0]) + 0.7152 * g(c[1]) + 0.0722 * g(c[2])


def ratio(a, b):
    x, y = sorted([lum(a), lum(b)], reverse=True)
    return (x + 0.05) / (y + 0.05)


# (foreground, background, minimum, what it is)
TEXT = 4.5
UI = 3.0
_SURF = ["--color-canvas-bg", "--color-card-surface", "--color-surface-sunken"]
PAIRS = (
    [(fg, bg, TEXT, "body text") for fg in ("--color-text-primary", "--color-text-secondary", "--color-text-tertiary")
     for bg in _SURF + ["GLASS"]]
    + [("--color-text-primary", bg, TEXT, "path labels / bubble") for bg in
       ("--color-meadow-sky", "--color-meadow-sky-bottom", "--color-meadow-hill-distant", "--color-meadow-hill-mid",
        "--color-meadow-hill-near", "--color-accent-subtle", "--color-gold-subtle")]
    + [("--color-text-secondary", bg, TEXT, "path labels") for bg in
       ("--color-meadow-sky", "--color-meadow-sky-bottom", "--color-meadow-hill-mid", "--color-meadow-hill-near")]
    + [("--color-accent", bg, TEXT, "accent text") for bg in _SURF + ["--color-accent-subtle", "GLASS"]]
    + [("--color-on-accent", "--color-accent-fill", TEXT, "button label")]
    + [("--color-gold", bg, TEXT, "reward text") for bg in _SURF + ["--color-gold-subtle"]]
    + [("--color-success", bg, TEXT, "quiz correct") for bg in ("--color-card-surface", "--color-success-subtle", "--color-canvas-bg")]
    + [("--color-error", bg, TEXT, "quiz wrong") for bg in ("--color-card-surface", "--color-error-subtle", "--color-canvas-bg")]
    + [("--color-on-accent", "--color-success-fill", TEXT, "correct button label")]
    + [("--color-note", "--color-note-subtle", TEXT, "design note")]
    + [("--color-accent-fill", bg, UI, "icon tint (non-text)") for bg in ("--color-canvas-bg", "--color-card-surface")]
    + [("NODE", "--color-meadow-hill-near", UI, "current node (fill or ring) on hill (non-text)")]
)


def check(direction, verbose=False):
    t = tokens(direction)
    rows, fails = [], 0
    for mode_i, mode in enumerate(("light", "dark")):
        canvas = t["--color-canvas-bg"][mode_i]
        glass = over(t["--color-glass-fill"][mode_i], canvas)
        for fg, bg, need, what in PAIRS:
            bgv = glass if bg == "GLASS" else t[bg][mode_i]
            if fg == "NODE":
                fill, ring = t["--color-accent-fill"][mode_i], t["--color-node-current-ring"][mode_i]
                fgv = fill if ratio(fill, bgv) >= ratio(ring, bgv) else ring
            else:
                fgv = t[fg][mode_i]
            if len(bgv) == 9:
                bgv = over(bgv, canvas)
            if len(fgv) == 9:
                fgv = over(fgv, bgv)
            r = ratio(fgv, bgv)
            ok = r >= need
            fails += not ok
            rows.append((mode, fg, "glass over canvas" if bg == "GLASS" else bg, fgv, bgv, r, need, what, ok))
    return rows, fails


if __name__ == "__main__":
    which = sys.argv[2:] or list(DIRECTIONS)
    total = 0
    for d in which:
        rows, f = check(d)
        total += f
        n_text = sum(1 for r in rows if r[6] == TEXT)
        print(f"{DIRECTIONS[d]['name']}: {len(rows)} pairs ({n_text} text, {len(rows) - n_text} non-text), {f} failures")
        for r in rows:
            if not r[8] or "-v" in sys.argv[1:2]:
                print(f"   {'FAIL' if not r[8] else 'ok  '} {r[0]:5} {r[1]} on {r[2]}: {r[3]} / {r[4]} = {r[5]:.2f} (need {r[6]})")
    sys.exit(1 if total else 0)
