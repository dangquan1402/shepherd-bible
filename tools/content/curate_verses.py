#!/usr/bin/env python3
"""Write daily_verses.json: 366 hand-picked verse-of-the-day entries from the WEB.

Every reference is listed by hand below (183 OT, 183 NT) and chosen to be comforting,
well known and non-controversial. Each verse must read as a complete sentence on its
own in the WEB wording and fit the small Home Screen widget, so the script applies the
same rules as validate_content.py (length cap, no sentence fragments) and refuses to
write the file if any entry breaks them. OT and NT entries alternate day by day.

Usage: python3 -I tools/content/curate_verses.py
"""

import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from validate_content import DAILY_VERSE_MAX_CHARS, FRAGMENT_END

ROOT = os.path.dirname(os.path.dirname(HERE))
WEB_PATH = os.path.join(ROOT, "Shepherd", "Resources", "Content", "web.json")
OUT_PATH = os.path.join(ROOT, "Shepherd", "Resources", "Content", "daily_verses.json")
PER_TESTAMENT = 183

# fmt: off
ot_candidates = [
    # Genesis
    "GEN.1.1", "GEN.1.3", "GEN.1.27", "GEN.1.31", "GEN.8.22", "GEN.9.13", "GEN.12.2",
    # Exodus
    "EXO.14.14", "EXO.15.2", "EXO.15.13", "EXO.20.12", "EXO.33.14",
    # Numbers
    "NUM.6.24", "NUM.6.25", "NUM.6.26",
    # Deuteronomy
    "DEU.6.5", "DEU.31.8", "DEU.32.4", "DEU.33.27",
    # Joshua
    "JOS.1.9", "JOS.21.45",
    # Ruth
    "RUT.2.12",
    # 1 & 2 Samuel
    "1SA.2.2", "1SA.12.24", "2SA.22.3", "2SA.22.29", "2SA.22.31",
    # 1 & 2 Kings
    "1KI.8.61", "2KI.6.16",
    # 1 & 2 Chronicles
    "1CH.16.11", "1CH.16.34", "1CH.29.13", "2CH.15.7",
    # Ezra
    "EZR.7.10",
    # Job
    "JOB.19.25", "JOB.23.10", "JOB.37.14",
    # Psalms
    "PSA.3.3", "PSA.3.5", "PSA.4.8", "PSA.5.3", "PSA.8.1", "PSA.8.9", "PSA.9.1",
    "PSA.9.10", "PSA.16.8", "PSA.16.11", "PSA.18.1", "PSA.18.2", "PSA.18.30",
    "PSA.19.1", "PSA.19.14", "PSA.20.7", "PSA.23.1", "PSA.23.2", "PSA.23.3", "PSA.23.4",
    "PSA.23.5", "PSA.23.6", "PSA.24.1", "PSA.25.4", "PSA.25.5", "PSA.27.1", "PSA.27.14",
    "PSA.29.11", "PSA.30.5", "PSA.31.24", "PSA.32.7", "PSA.32.8", "PSA.33.4",
    "PSA.33.20", "PSA.34.1", "PSA.34.4", "PSA.34.8", "PSA.34.18", "PSA.36.7",
    "PSA.37.3", "PSA.37.4", "PSA.37.23", "PSA.37.39", "PSA.40.1", "PSA.42.1",
    "PSA.46.1", "PSA.46.10", "PSA.51.10", "PSA.55.22", "PSA.56.3", "PSA.61.2",
    "PSA.62.1", "PSA.62.5", "PSA.63.1", "PSA.63.3", "PSA.65.11", "PSA.68.19",
    "PSA.71.5", "PSA.73.26", "PSA.84.11", "PSA.86.5", "PSA.86.11", "PSA.86.15",
    "PSA.90.12", "PSA.90.14", "PSA.91.1", "PSA.91.2", "PSA.91.4", "PSA.91.11",
    "PSA.95.1", "PSA.96.1", "PSA.100.1", "PSA.100.2", "PSA.100.3", "PSA.100.4",
    "PSA.100.5", "PSA.103.1", "PSA.103.8", "PSA.103.11", "PSA.103.12", "PSA.103.13",
    "PSA.105.1", "PSA.107.1", "PSA.112.7", "PSA.116.1", "PSA.118.1", "PSA.118.14",
    "PSA.118.24", "PSA.119.11", "PSA.119.50", "PSA.119.105", "PSA.119.114",
    "PSA.119.130", "PSA.121.1", "PSA.121.2", "PSA.121.5", "PSA.121.8", "PSA.126.3",
    "PSA.127.1", "PSA.130.5", "PSA.133.1", "PSA.136.1", "PSA.138.8", "PSA.139.1",
    "PSA.139.5", "PSA.139.14", "PSA.139.23", "PSA.139.24", "PSA.145.3", "PSA.145.8",
    "PSA.145.9", "PSA.145.14", "PSA.145.18", "PSA.147.3", "PSA.150.6",
    # Proverbs
    "PRO.3.3", "PRO.3.5", "PRO.3.6", "PRO.4.18", "PRO.4.23", "PRO.15.1", "PRO.16.3",
    "PRO.16.9", "PRO.16.24", "PRO.17.17", "PRO.17.22", "PRO.18.10", "PRO.19.21",
    # Isaiah
    "ISA.12.2", "ISA.26.3", "ISA.40.8", "ISA.40.29", "ISA.41.13", "ISA.43.19",
    "ISA.49.15", "ISA.49.16",
    # Jeremiah & Lamentations
    "JER.17.7", "JER.29.11", "JER.29.13", "JER.31.3", "JER.33.3", "LAM.3.22",
    "LAM.3.23", "LAM.3.25",
    # Minor Prophets
    "MIC.6.8", "NAM.1.7",
]

nt_candidates = [
    # Matthew
    "MAT.5.3", "MAT.5.4", "MAT.5.5", "MAT.5.6", "MAT.5.7", "MAT.5.8", "MAT.5.9",
    "MAT.5.14", "MAT.5.16", "MAT.6.14", "MAT.6.33", "MAT.6.34", "MAT.7.7", "MAT.7.8",
    "MAT.7.12", "MAT.10.29", "MAT.10.31", "MAT.11.28", "MAT.11.29", "MAT.11.30",
    "MAT.18.20", "MAT.19.26", "MAT.22.37", "MAT.22.39", "MAT.24.35",
    # Mark
    "MRK.8.35", "MRK.9.23", "MRK.10.27", "MRK.10.45", "MRK.11.24", "MRK.12.31",
    # Luke
    "LUK.1.37", "LUK.1.49", "LUK.2.10", "LUK.2.14", "LUK.6.31", "LUK.6.36", "LUK.6.37",
    "LUK.11.9", "LUK.12.24", "LUK.12.32", "LUK.12.34", "LUK.15.7", "LUK.15.10", "LUK.18.27",
    "LUK.19.10",
    # John
    "JHN.1.1", "JHN.1.4", "JHN.1.5", "JHN.1.14", "JHN.1.16", "JHN.3.16", "JHN.3.17",
    "JHN.4.24", "JHN.6.35", "JHN.6.37", "JHN.8.32", "JHN.10.9", "JHN.10.10", "JHN.10.11",
    "JHN.10.27", "JHN.10.28", "JHN.11.25", "JHN.13.34", "JHN.13.35", "JHN.14.1",
    "JHN.14.2", "JHN.14.6", "JHN.14.15", "JHN.14.18", "JHN.14.27", "JHN.15.4",
    "JHN.15.5", "JHN.15.9", "JHN.15.12", "JHN.15.13", "JHN.16.33", "JHN.17.3",
    # Acts
    "ACT.2.42", "ACT.4.12", "ACT.16.31", "ACT.17.28",
    # Romans
    "ROM.5.8", "ROM.6.23", "ROM.8.1", "ROM.8.14", "ROM.8.15", "ROM.8.18", "ROM.8.28",
    "ROM.8.31", "ROM.8.32", "ROM.8.35", "ROM.8.37", "ROM.10.10", "ROM.10.13",
    "ROM.11.36", "ROM.12.9", "ROM.12.18", "ROM.12.21", "ROM.15.7", "ROM.15.13",
    # 1 Corinthians
    "1CO.1.9", "1CO.1.18", "1CO.10.31", "1CO.13.13", "1CO.15.57", "1CO.16.13",
    "1CO.16.14",
    # 2 Corinthians
    "2CO.3.17", "2CO.4.16", "2CO.5.17", "2CO.5.21", "2CO.9.8", "2CO.13.14",
    # Galatians
    "GAL.5.13", "GAL.6.2", "GAL.6.9", "GAL.6.10",
    # Ephesians
    "EPH.2.10", "EPH.4.32", "EPH.5.1", "EPH.5.2", "EPH.6.10", "EPH.6.11",
    # Philippians
    "PHP.2.13", "PHP.3.14", "PHP.4.4", "PHP.4.5", "PHP.4.6", "PHP.4.7",
    "PHP.4.11", "PHP.4.13", "PHP.4.19",
    # Colossians
    "COL.1.17", "COL.3.1", "COL.3.2", "COL.3.14", "COL.3.15", "COL.3.17",
    # 1 & 2 Thessalonians
    "1TH.5.11", "1TH.5.16", "1TH.5.17", "1TH.5.18", "1TH.5.24", "2TH.3.3", "2TH.3.16",
    # 1 & 2 Timothy
    "1TI.1.15", "1TI.4.12", "1TI.6.6", "2TI.1.7", "2TI.2.13", "2TI.4.7",
    # Hebrews
    "HEB.4.16", "HEB.11.1", "HEB.13.6", "HEB.13.8", "HEB.13.15", "HEB.13.16",
    # James
    "JAS.1.5", "JAS.1.17", "JAS.1.22", "JAS.4.7", "JAS.4.10", "JAS.5.16",
    # 1 & 2 Peter
    "1PE.4.8", "2PE.3.18",
    # 1 John
    "1JN.1.9", "1JN.3.16", "1JN.3.18", "1JN.4.7", "1JN.4.8", "1JN.4.9", "1JN.4.10",
    "1JN.4.12", "1JN.4.16", "1JN.4.18", "1JN.4.19", "1JN.5.4", "1JN.5.14",
    # Revelation
    "REV.1.8", "REV.3.20", "REV.21.5", "REV.22.20",
]

# fmt: on


def load_verses():
    """Map "BOOK.chapter.verse" to its testament and WEB text."""
    with open(WEB_PATH, "r", encoding="utf-8") as f:
        web = json.load(f)
    verses = {}
    for book in web["books"]:
        for chapter in book["chapters"]:
            for verse in chapter["verses"]:
                ref = f"{book['abbrev']}.{chapter['number']}.{verse['number']}"
                verses[ref] = {"testament": book["testament"], "text": verse["text"]}
    return verses


def dedupe(refs):
    seen = set()
    return [r for r in refs if not (r in seen or seen.add(r))]


def problems(ref, verses, testament):
    """Return why `ref` can't be a daily verse (mirrors validate_daily_verses)."""
    if ref not in verses:
        return ["not in web.json"]
    errs = []
    verse = verses[ref]
    text = verse["text"]
    if verse["testament"] != testament:
        errs.append(f"is {verse['testament']}, listed under {testament}")
    if len(text) > DAILY_VERSE_MAX_CHARS:
        errs.append(f"{len(text)} characters, over {DAILY_VERSE_MAX_CHARS}")
    stripped = text.rstrip("”’\"' ")
    if text[0].islower() or stripped.endswith(FRAGMENT_END):
        errs.append(f"sentence fragment: {text!r}")
    return errs


def main():
    verses = load_verses()
    ot = dedupe(ot_candidates)
    nt = dedupe(nt_candidates)

    errors = []
    for label, refs in (("OT", ot), ("NT", nt)):
        if len(refs) != PER_TESTAMENT:
            errors.append(f"{label} list has {len(refs)} refs, need {PER_TESTAMENT}")
        for ref in refs:
            errors.extend(f"{ref}: {e}" for e in problems(ref, verses, label))
    if errors:
        raise SystemExit("curate_verses: refusing to write:\n  " + "\n  ".join(errors))

    # Interleave OT and NT so daily readings alternate.
    daily = []
    for ot_ref, nt_ref in zip(ot, nt):
        for ref in (ot_ref, nt_ref):
            daily.append(
                {"day": len(daily) + 1, "ref": ref, "text": verses[ref]["text"]}
            )

    with open(OUT_PATH, "w", encoding="utf-8") as f:
        json.dump(daily, f, indent=2, ensure_ascii=False)
    print(f"Wrote {len(daily)} verses ({len(ot)} OT, {len(nt)} NT) to {OUT_PATH}")


if __name__ == "__main__":
    main()
