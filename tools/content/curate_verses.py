#!/usr/bin/env python3
"""Curate 366 comforting, well-known, non-controversial WEB verses (183 OT, 183 NT)."""

import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WEB_PATH = os.path.join(ROOT, "Shepherd", "Resources", "Content", "web.json")
OUT_PATH = os.path.join(ROOT, "Shepherd", "Resources", "Content", "daily_verses.json")

with open(WEB_PATH, "r", encoding="utf-8") as f:
    web = json.load(f)

# Build index: ref -> (testament, book_name, text)
verse_index = {}
for book in web["books"]:
    t = book["testament"]
    bname = book["name"]
    babbrev = book["abbrev"]
    for chapter in book["chapters"]:
        cnum = chapter["number"]
        for verse in chapter["verses"]:
            vnum = verse["number"]
            ref = f"{babbrev}.{cnum}.{vnum}"
            verse_index[ref] = {
                "testament": t,
                "book": babbrev,
                "bookName": bname if babbrev != "PSA" else "Psalm",
                "chapter": cnum,
                "verse": vnum,
                "text": verse["text"]
            }

ot_candidates = [
    # Genesis
    "GEN.1.1", "GEN.1.3", "GEN.1.27", "GEN.1.31", "GEN.8.22", "GEN.12.2", "GEN.28.15",
    # Exodus
    "EXO.14.14", "EXO.15.2", "EXO.20.12", "EXO.33.14", "EXO.34.6",
    # Numbers
    "NUM.6.24", "NUM.6.25", "NUM.6.26",
    # Deuteronomy
    "DEU.6.5", "DEU.7.9", "DEU.31.6", "DEU.31.8", "DEU.33.27",
    # Joshua
    "JOS.1.8", "JOS.1.9", "JOS.24.15",
    # Ruth
    "RUT.1.16",
    # 1 & 2 Samuel
    "1SA.12.24", "1SA.16.7", "2SA.7.22", "2SA.22.3", "2SA.22.31",
    # 1 & 2 Kings
    "1KI.8.61", "2KI.6.16",
    # 1 & 2 Chronicles
    "1CH.16.11", "1CH.16.34", "1CH.29.11", "2CH.7.14", "2CH.15.7", "2CH.16.9", "2CH.20.12",
    # Ezra & Nehemiah
    "EZR.7.10", "NEH.8.10", "NEH.9.17",
    # Job
    "JOB.19.25", "JOB.23.10", "JOB.37.14",
    # Psalms
    "PSA.1.1", "PSA.1.2", "PSA.1.3", "PSA.3.3", "PSA.3.5", "PSA.4.8", "PSA.5.3", "PSA.8.1",
    "PSA.8.9", "PSA.9.1", "PSA.9.10", "PSA.16.8", "PSA.16.11", "PSA.18.1", "PSA.18.2", "PSA.18.30",
    "PSA.19.1", "PSA.19.14", "PSA.20.7", "PSA.23.1", "PSA.23.2", "PSA.23.3", "PSA.23.4", "PSA.23.5", "PSA.23.6",
    "PSA.24.1", "PSA.25.4", "PSA.25.5", "PSA.27.1", "PSA.27.4", "PSA.27.14", "PSA.28.7", "PSA.29.11", "PSA.30.5",
    "PSA.31.24", "PSA.32.7", "PSA.32.8", "PSA.33.4", "PSA.33.20", "PSA.34.1", "PSA.34.4", "PSA.34.8", "PSA.34.18",
    "PSA.36.7", "PSA.37.3", "PSA.37.4", "PSA.37.5", "PSA.37.23", "PSA.37.39", "PSA.40.1", "PSA.42.1", "PSA.46.1",
    "PSA.46.10", "PSA.51.10", "PSA.55.22", "PSA.56.3", "PSA.57.1", "PSA.61.2", "PSA.62.1", "PSA.62.5", "PSA.63.1",
    "PSA.63.3", "PSA.65.11", "PSA.68.19", "PSA.71.5", "PSA.73.26", "PSA.84.11", "PSA.86.5", "PSA.86.11", "PSA.86.15",
    "PSA.90.12", "PSA.90.14", "PSA.91.1", "PSA.91.2", "PSA.91.4", "PSA.91.11", "PSA.92.1", "PSA.95.1", "PSA.95.6",
    "PSA.96.1", "PSA.100.1", "PSA.100.2", "PSA.100.3", "PSA.100.4", "PSA.100.5", "PSA.103.1", "PSA.103.2", "PSA.103.8",
    "PSA.103.11", "PSA.103.12", "PSA.103.13", "PSA.105.1", "PSA.107.1", "PSA.112.7", "PSA.116.1", "PSA.118.1", "PSA.118.14",
    "PSA.118.24", "PSA.119.11", "PSA.119.50", "PSA.119.105", "PSA.119.114", "PSA.119.130", "PSA.121.1", "PSA.121.2", "PSA.121.5",
    "PSA.121.8", "PSA.126.3", "PSA.127.1", "PSA.130.5", "PSA.133.1", "PSA.136.1", "PSA.138.8", "PSA.139.1", "PSA.139.5",
    "PSA.139.14", "PSA.139.23", "PSA.139.24", "PSA.143.8", "PSA.145.3", "PSA.145.8", "PSA.145.9", "PSA.145.14", "PSA.145.18",
    "PSA.147.3", "PSA.150.6",
    # Proverbs
    "PRO.3.3", "PRO.3.5", "PRO.3.6", "PRO.4.18", "PRO.4.23", "PRO.15.1", "PRO.16.3", "PRO.16.9", "PRO.16.24",
    "PRO.17.17", "PRO.17.22", "PRO.18.10", "PRO.19.21", "PRO.22.1", "PRO.27.17", "PRO.27.19", "PRO.30.5",
    # Ecclesiastes
    "ECC.3.1", "ECC.3.11", "ECC.4.9", "ECC.12.13",
    # Song of Solomon
    "SNG.2.16",
    # Isaiah
    "ISA.9.6", "ISA.12.2", "ISA.25.1", "ISA.26.3", "ISA.26.4", "ISA.30.15", "ISA.30.18", "ISA.30.21",
    "ISA.40.8", "ISA.40.11", "ISA.40.29", "ISA.40.31", "ISA.41.10", "ISA.41.13", "ISA.43.1", "ISA.43.2",
    "ISA.43.19", "ISA.44.22", "ISA.49.15", "ISA.49.16", "ISA.53.5", "ISA.54.10", "ISA.55.6", "ISA.55.8",
    "ISA.55.9", "ISA.55.11", "ISA.58.11", "ISA.60.1", "ISA.61.1", "ISA.61.3",
    # Jeremiah & Lamentations
    "JER.17.7", "JER.17.8", "JER.29.11", "JER.29.12", "JER.29.13", "JER.31.3", "JER.32.17", "JER.33.3",
    "LAM.3.22", "LAM.3.23", "LAM.3.24", "LAM.3.25", "LAM.3.26",
    # Ezekiel & Daniel
    "EZK.34.15", "EZK.36.26", "DAN.2.22", "DAN.12.3",
    # Minor Prophets
    "HOS.6.3", "HOS.6.6", "HOS.10.12", "JOL.2.13", "JOL.2.28", "AMO.5.24", "MIC.6.8", "MIC.7.18", "MIC.7.19",
    "NAM.1.7", "HAB.3.19", "ZEP.3.17", "HAG.2.9", "ZEC.4.6", "MAL.3.10", "MAL.4.2"
]

nt_candidates = [
    # Matthew
    "MAT.5.3", "MAT.5.4", "MAT.5.5", "MAT.5.6", "MAT.5.7", "MAT.5.8", "MAT.5.9", "MAT.5.14", "MAT.5.16",
    "MAT.6.14", "MAT.6.21", "MAT.6.26", "MAT.6.33", "MAT.6.34", "MAT.7.7", "MAT.7.8", "MAT.7.12", "MAT.10.29",
    "MAT.10.31", "MAT.11.28", "MAT.11.29", "MAT.11.30", "MAT.18.20", "MAT.19.26", "MAT.22.37", "MAT.22.39",
    "MAT.28.19", "MAT.28.20",
    # Mark
    "MRK.8.35", "MRK.9.23", "MRK.10.27", "MRK.10.45", "MRK.11.24", "MRK.12.30", "MRK.12.31",
    # Luke
    "LUK.1.37", "LUK.1.49", "LUK.2.10", "LUK.2.14", "LUK.6.31", "LUK.6.35", "LUK.6.36", "LUK.6.37", "LUK.6.38",
    "LUK.10.27", "LUK.11.9", "LUK.12.32", "LUK.15.7", "LUK.15.10", "LUK.18.27", "LUK.19.10", "LUK.24.6",
    # John
    "JHN.1.1", "JHN.1.4", "JHN.1.5", "JHN.1.12", "JHN.1.14", "JHN.1.16", "JHN.3.16", "JHN.3.17", "JHN.4.14",
    "JHN.4.24", "JHN.6.35", "JHN.8.12", "JHN.8.32", "JHN.10.10", "JHN.10.11", "JHN.10.14", "JHN.10.27", "JHN.10.28",
    "JHN.11.25", "JHN.13.34", "JHN.13.35", "JHN.14.1", "JHN.14.2", "JHN.14.6", "JHN.14.15", "JHN.14.27", "JHN.15.4",
    "JHN.15.5", "JHN.15.9", "JHN.15.12", "JHN.15.13", "JHN.16.33", "JHN.17.3",
    # Acts
    "ACT.1.8", "ACT.2.42", "ACT.4.12", "ACT.16.31", "ACT.17.28", "ACT.20.35",
    # Romans
    "ROM.1.16", "ROM.5.1", "ROM.5.5", "ROM.5.8", "ROM.6.23", "ROM.8.1", "ROM.8.14", "ROM.8.18", "ROM.8.26",
    "ROM.8.28", "ROM.8.31", "ROM.8.32", "ROM.8.35", "ROM.8.37", "ROM.8.38", "ROM.8.39", "ROM.10.9", "ROM.10.10",
    "ROM.10.13", "ROM.12.1", "ROM.12.2", "ROM.12.9", "ROM.12.10", "ROM.12.12", "ROM.12.18", "ROM.12.21",
    "ROM.15.5", "ROM.15.13",
    # 1 Corinthians
    "1CO.1.18", "1CO.2.9", "1CO.6.19", "1CO.10.13", "1CO.13.4", "1CO.13.5", "1CO.13.6", "1CO.13.7", "1CO.13.8",
    "1CO.13.13", "1CO.15.57", "1CO.15.58", "1CO.16.13", "1CO.16.14",
    # 2 Corinthians
    "2CO.1.3", "2CO.1.4", "2CO.3.17", "2CO.4.16", "2CO.4.17", "2CO.4.18", "2CO.5.7", "2CO.5.17", "2CO.5.21",
    "2CO.9.8", "2CO.12.9",
    # Galatians
    "GAL.2.20", "GAL.5.13", "GAL.5.22", "GAL.5.23", "GAL.6.2", "GAL.6.9", "GAL.6.10",
    # Ephesians
    "EPH.1.3", "EPH.2.4", "EPH.2.8", "EPH.2.9", "EPH.2.10", "EPH.3.16", "EPH.3.17", "EPH.3.20", "EPH.4.1",
    "EPH.4.2", "EPH.4.32", "EPH.5.1", "EPH.5.2", "EPH.6.10", "EPH.6.11", "EPH.6.18",
    # Philippians
    "PHP.1.6", "PHP.2.3", "PHP.2.4", "PHP.2.13", "PHP.3.13", "PHP.3.14", "PHP.4.4", "PHP.4.5", "PHP.4.6",
    "PHP.4.7", "PHP.4.8", "PHP.4.11", "PHP.4.12", "PHP.4.13", "PHP.4.19",
    # Colossians
    "COL.1.13", "COL.1.17", "COL.3.1", "COL.3.2", "COL.3.12", "COL.3.13", "COL.3.14", "COL.3.15", "COL.3.16",
    "COL.3.17", "COL.3.23",
    # 1 & 2 Thessalonians
    "1TH.5.11", "1TH.5.16", "1TH.5.17", "1TH.5.18", "1TH.5.24", "2TH.3.3", "2TH.3.16",
    # 1 & 2 Timothy & Titus
    "1TI.1.15", "1TI.4.12", "1TI.6.6", "1TI.6.12", "2TI.1.7", "2TI.2.13", "2TI.3.16", "2TI.3.17", "2TI.4.7",
    "TIT.2.11", "TIT.3.4", "TIT.3.5",
    # Hebrews
    "HEB.4.12", "HEB.4.16", "HEB.10.23", "HEB.10.24", "HEB.11.1", "HEB.11.6", "HEB.12.1", "HEB.12.2", "HEB.13.5",
    "HEB.13.6", "HEB.13.8", "HEB.13.15", "HEB.13.16",
    # James
    "JAS.1.2", "JAS.1.3", "JAS.1.5", "JAS.1.12", "JAS.1.17", "JAS.1.19", "JAS.1.22", "JAS.3.17", "JAS.4.7",
    "JAS.4.8", "JAS.4.10", "JAS.5.16",
    # 1 & 2 Peter
    "1PE.1.3", "1PE.2.9", "1PE.3.15", "1PE.4.8", "1PE.5.6", "1PE.5.7", "1PE.5.10", "2PE.1.3", "2PE.3.9", "2PE.3.18",
    # 1 John & Jude
    "1JN.1.7", "1JN.1.9", "1JN.3.1", "1JN.3.16", "1JN.3.18", "1JN.4.7", "1JN.4.8", "1JN.4.9", "1JN.4.10", "1JN.4.12",
    "1JN.4.16", "1JN.4.18", "1JN.4.19", "1JN.5.4", "1JN.5.14", "JUD.1.24",
    # Revelation
    "REV.1.8", "REV.3.20", "REV.7.17", "REV.21.3", "REV.21.4", "REV.21.5", "REV.22.17", "REV.22.20"
]

# Deduplicate candidates while keeping order
seen_ot = set()
clean_ot = []
for r in ot_candidates:
    if r not in seen_ot:
        seen_ot.add(r)
        clean_ot.append(r)

seen_nt = set()
clean_nt = []
for r in nt_candidates:
    if r not in seen_nt:
        seen_nt.add(r)
        clean_nt.append(r)

print(f"Initial OT candidates: {len(clean_ot)}, NT candidates: {len(clean_nt)}")

# Validate all exist in web.json
missing_ot = [r for r in clean_ot if r not in verse_index]
missing_nt = [r for r in clean_nt if r not in verse_index]
if missing_ot or missing_nt:
    print(f"Missing OT: {missing_ot}")
    print(f"Missing NT: {missing_nt}")
    raise SystemExit(1)

# Ensure we have at least 183 OT and 183 NT
target_per_testament = 183

# If we need more OT or NT, let's find comforting Psalms or Gospels/Epistles
if len(clean_ot) < target_per_testament:
    extra_psalms = [
        f"PSA.{c}.{v}" for c in range(1, 151) for v in range(1, 10)
    ]
    for r in extra_psalms:
        if r in verse_index and r not in seen_ot:
            text = verse_index[r]["text"]
            # Filter for comforting themes: love, grace, goodness, praise, light
            if any(w in text.lower() for w in ["praise", "good", "mercy", "loving kindness", "heart", "blessed", "joy", "peace", "righteous", "glad"]):
                if not any(w in text.lower() for w in ["blood", "wicked", "enemy", "wrath", "slay", "destroy", "perish"]):
                    seen_ot.add(r)
                    clean_ot.append(r)
                    if len(clean_ot) == target_per_testament:
                        break

if len(clean_nt) < target_per_testament:
    # Add from John or Epistles
    extra_nt = []
    for babbrev in ["JHN", "ROM", "PHP", "COL", "1TH", "HEB", "1JN"]:
        for c in range(1, 15):
            for v in range(1, 25):
                r = f"{babbrev}.{c}.{v}"
                if r in verse_index and r not in seen_nt:
                    text = verse_index[r]["text"]
                    if any(w in text.lower() for w in ["love", "faith", "hope", "grace", "peace", "light", "joy", "life", "comfort", "glory", "truth"]):
                        if not any(w in text.lower() for w in ["wrath", "condemnation", "judgment", "perish", "curse", "hell", "fire", "destroy"]):
                            seen_nt.add(r)
                            clean_nt.append(r)
                            if len(clean_nt) == target_per_testament:
                                break
            if len(clean_nt) == target_per_testament:
                break

clean_ot = clean_ot[:target_per_testament]
clean_nt = clean_nt[:target_per_testament]

print(f"Final: {len(clean_ot)} OT, {len(clean_nt)} NT. Total = {len(clean_ot) + len(clean_nt)}")

# Interleave OT and NT so daily readings alternate
daily_items = []
day_num = 1
for ot_ref, nt_ref in zip(clean_ot, clean_nt):
    ot_v = verse_index[ot_ref]
    daily_items.append({
        "day": day_num,
        "ref": ot_ref,
        "text": ot_v["text"]
    })
    day_num += 1
    nt_v = verse_index[nt_ref]
    daily_items.append({
        "day": day_num,
        "ref": nt_ref,
        "text": nt_v["text"]
    })
    day_num += 1

with open(OUT_PATH, "w", encoding="utf-8") as f:
    json.dump(daily_items, f, indent=2, ensure_ascii=False)

print(f"Wrote {len(daily_items)} verses to {OUT_PATH}")
