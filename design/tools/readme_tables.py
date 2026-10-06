#!/usr/bin/env python3
"""Regenerate the generated sections of design/README.md from the design files and the app's JSON.

Read-only on every .pen file (it parses the JSON; it never writes a .pen). It rewrites only the text between
<!-- gen:NAME --> and <!-- /gen:NAME --> markers in design/README.md.

    python3 design/tools/readme_tables.py          # from the repo root
"""

import json
import os
import re
from collections import Counter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
D = os.path.join(ROOT, "design")


def read_text(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def read_json(path):
    return json.loads(read_text(path))


LIB = read_json(os.path.join(D, "shepherd.lib.pen"))
SCR = read_json(os.path.join(D, "screens", "shepherd.pen"))
PATHS = read_json(os.path.join(ROOT, "Shepherd/Resources/Content/paths.json"))["paths"]
BIBLE = read_json(os.path.join(ROOT, "Shepherd/Resources/Content/web.json"))


def walk(n):
    yield n
    for c in n.get("children") or []:
        yield from walk(c)


def themed(v):
    val = v["value"]
    if isinstance(val, list):
        m = {e.get("theme", {}).get("mode"): e["value"] for e in val}
        return m.get("light", "—"), m.get("dark", "—")
    return val, val


def gen_tokens():
    groups = [
        (
            "Colour: text and surfaces",
            r"^--color-(canvas|card|surface|text|on-accent|transparent|phone)",
        ),
        ("Colour: accent, gold, reward", r"^--color-(accent|gold|node)"),
        ("Colour: quiz correctness (quiz only)", r"^--color-(success|error)"),
        (
            "Colour: Liquid Glass",
            r"^--color-(glass|shadow|scrim|tab|canvas-clear|canvas-veil)",
        ),
        ("Colour: meadow illustration", r"^--color-meadow"),
        ("Colour: lamb", r"^--color-mascot"),
        ("Colour: app icon (light = default appearance, dark = dark appearance)", r"^--color-icon"),
        ("Colour: design notes (not shipped UI)", r"^--color-note"),
        ("Type", r"^--(font|text|weight)"),
        ("Radius and spacing", r"^--(radius|space)"),
    ]
    V = LIB["variables"]
    used = set()
    out = []
    for title, rx in groups:
        rows = [k for k in V if re.search(rx, k) and k not in used]
        if not rows:
            continue
        used.update(rows)
        out.append(f"\n**{title}**\n\n| Token | Light | Dark |\n|---|---|---|")
        for k in rows:
            l, d = themed(V[k])
            out.append(f"| `{k}` | `{l}` | `{d}` |")
    rest = [k for k in V if k not in used]
    if rest:
        out.append("\n**Other**\n\n| Token | Light | Dark |\n|---|---|---|")
        for k in rest:
            l, d = themed(V[k])
            out.append(f"| `{k}` | `{l}` | `{d}` |")
    return (
        f"{len(V)} variables in `shepherd.lib.pen` (theme axis `mode`: light / dark).\n"
        + "\n".join(out)
    )


PURPOSE = {
    "Sys/": "iPhone system chrome (status bar with black Dynamic Island, home indicator)",
    "Nav/GlassButton": "44 pt circular glass toolbar button; icon swapped per use",
    "Nav/StreakChip": "glass toolbar chip: flame + current streak",
    "Nav/GlassPillButton": "glass text button for toolbars",
    "Nav/TabBar/": "glass tab bar, one variant per selected tab",
    "Nav/TabBarMin/": "minimized tab bar (single glass circle) after scroll-down",
    "Nav/Accessory/Expanded": "tabViewBottomAccessory, expanded placement",
    "Nav/Accessory/Inline": "tabViewBottomAccessory, inline placement",
    "Button/Prominent": "primary action (.glassProminent tinted ultramarine)",
    "Button/ProminentDisabled": "primary action, disabled",
    "Button/Glass": "secondary action (.glass)",
    "Button/Text": "plain text action",
    "Path/Node/": "3D path node (face + deep lip)",
    "Row/Choice/": "quiz answer row state",
    "Bar/Progress": "progress / XP bar (fill width overridden)",
    "Chip/Stat": "reward chip (+XP, streak)",
    "Card/Verse": "verse card: reference + translation, serif verse text",
    "Row/Option/": "onboarding option row",
    "Card/Plan/": "paywall plan card",
    "Row/Settings": "settings row (label, value, chevron)",
    "Sheet/Feedback/": "glass quiz feedback sheet (morph target of Check)",
    "Lamb/": "lamb character variant (vector layers)",
    "Avatar/": "lamb head-and-shoulders avatar (56 pt, pre-cut to the circle)",
    "Icon/LambGlyph": "24 pt lamb template glyph for the Lamb tab",
    "Mascot/CharacterSheet": "all 30 lamb variants with stage labels",
    "Brand/Mark": "logo mark: the lamb face on an ultramarine chip",
    "Brand/Wordmark": "lowercase wordmark, outlined Baloo 2 ExtraBold (SIL OFL 1.1)",
    "Brand/Lockup/Compact": "mark + wordmark, paywall header size",
    "Brand/Lockup": "mark + wordmark, onboarding welcome size",
    "Brand/AppIcon": "app icon artwork at 180 px (60 pt @3x); theme picks default / dark",
}


def purpose(name):
    for k, v in PURPOSE.items():
        if name.startswith(k):
            return v
    return ""


def gen_components():
    comps = [n for t in LIB["children"] for n in walk(t) if n.get("reusable")]
    lambs = [c for c in comps if c["name"].startswith("Lamb/")]
    other = [c for c in comps if not c["name"].startswith("Lamb/")]
    out = [
        f"{len(comps)} published components ({len(lambs)} lamb variants + {len(other)} others).\n",
        "| Component | Size (pt) | Children | Purpose |",
        "|---|---|---|---|",
    ]
    for c in other:
        kinds = Counter(x.get("type") for x in walk(c) if x is not c)
        k = ", ".join(f"{v} {t}" for t, v in sorted(kinds.items()))
        out.append(
            f"| `{c['name']}` | {c.get('width')}×{c.get('height')} | {k} | {purpose(c['name'])} |"
        )
    out.append("\n| Lamb variant | Artboard (pt) | Vector layers |\n|---|---|---|")
    for c in lambs:
        out.append(
            f"| `{c['name']}` | {c.get('width')}×{c.get('height')} | {len(c.get('children') or [])} paths |"
        )
    return "\n".join(out)


def gen_frames():
    idx = [
        row.split("\t")
        for row in read_text(os.path.join(D, "exports", "index.tsv")).split("\n")
        if row
    ]
    frames = {c["name"]: c for c in SCR["children"]}
    bases = []
    for _, f in idx:
        b = re.sub(r"_(Light|Dark)\.png$", "", f)
        if b not in bases:
            bases.append(b)
    total_refs = json.dumps(SCR).count('"type": "ref"')
    out = [
        f"{len(frames)} top-level frames ({len(bases)} screens × light/dark), {total_refs} library instances in the file.\n",
        "| Screen | Size | Instances per frame | Exports |",
        "|---|---|---|---|",
    ]
    for b in bases:
        L = frames.get(b + "_Light")
        refs = sum(1 for n in walk(L) if n.get("type") == "ref") if L else 0
        out.append(
            f"| `{b}` | {L.get('width')}×{L.get('height')} | {refs} | [Light](exports/{b}_Light.png) · [Dark](exports/{b}_Dark.png) |"
        )
    return "\n".join(out)


def gen_content():
    p = PATHS[0]
    books = {b["abbrev"]: b for b in BIBLE["books"]}

    def verse(ref):
        ab, c, v = ref.split(".")
        b = books[ab]
        ch = next(x for x in b["chapters"] if x["number"] == int(c))
        vv = next(x for x in ch["verses"] if x["number"] == int(v))
        return f"{b['name']} {c}:{v}", vv["text"]

    out = [
        f'Path `{p["id"]}`: "{p["title"]}" (level `{p["level"]}`, `estimatedDays` {p["estimatedDays"]}, {len(p["lessons"])} lessons). Translation label in the JSON: `{BIBLE["translation"]}`.\n',
        "| Day | Lesson id | Title | Verses | Questions (explain present?) |",
        "|---|---|---|---|---|",
    ]
    for l in p["lessons"]:
        qs = "; ".join(
            f"`{q['id']}` {'yes' if q.get('explain') else 'null'}" for q in l["quiz"]
        )
        out.append(
            f"| {l['dayIndex']} | `{l['id']}` | {l['title']} | {', '.join(l['verseRefs'])} | {qs} |"
        )
    l = p["lessons"][0]
    out.append(f"\n**Day 1, verbatim** (`{l['id']}`)\n")
    for r in l["verseRefs"]:
        lab, t = verse(r)
        out.append(f'- {lab} ({BIBLE["translation"]}): "{t}"')
    out.append(f'- Body: "{l["bodyMarkdown"]}"'.replace("\n", " "))
    out.append(f'- Prayer: "{l["prayerPrompt"]}"')
    for q in l["quiz"]:
        ch = " · ".join(f'{"ABCD"[i]} "{c}"' for i, c in enumerate(q["choices"]))
        out.append(
            f'- `{q["id"]}` "{q["prompt"]}": {ch}; correct {"ABCD"[q["correctIndex"]]}; explain: {json.dumps(q["explain"], ensure_ascii=False)}'
        )
    chapters = sum(len(b["chapters"]) for b in BIBLE["books"])
    out.append(f"\nBundled Bible: {BIBLE['name']}, {len(BIBLE['books'])} books, {chapters} chapters.")
    return "\n".join(out)


GEN = {
    "tokens": gen_tokens,
    "components": gen_components,
    "frames": gen_frames,
    "content": gen_content,
}


def main():
    path = os.path.join(D, "README.md")
    s = read_text(path)
    for name, fn in GEN.items():
        a, b = f"<!-- gen:{name} -->", f"<!-- /gen:{name} -->"
        if a not in s:
            raise SystemExit(f"marker {a} missing")
        i, j = s.index(a) + len(a), s.index(b)
        s = s[:i] + "\n" + fn() + "\n" + s[j:]
    with open(path, "w", encoding="utf-8") as f:
        f.write(s)
    print("regenerated:", ", ".join(GEN))


if __name__ == "__main__":
    main()
