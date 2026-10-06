#!/usr/bin/env python3
"""Summarise Shepherd's lesson content as Markdown tables (for PR bodies and content reviews).

    python3 -I tools/content/content_summary.py
    python3 -I tools/content/content_summary.py --lessons   # add one row per lesson

Per path: lessons, questions, words of lesson copy and of Scripture per lesson, where the
correct answer sits (as authored, and as the app displays it after QuizRules.displayOrder),
and verse references per book. Python 3.9+, stdlib only.
"""

import argparse
import json
import os
import re
import statistics
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CONTENT = os.path.join(ROOT, "Shepherd", "Resources", "Content")
MASK = (1 << 64) - 1


def fnv1a(s):
    h = 0xCBF29CE484222325
    for byte in s.encode("utf-8"):
        h ^= byte
        h = (h * 0x00000100000001B3) & MASK
    return h


def display_order(question):
    """Python port of QuizRules.displayOrder (Shepherd/Models/QuizRules.swift)."""
    order = list(range(len(question["choices"])))
    state = fnv1a(question["id"])
    for i in range(len(order) - 1, 0, -1):
        state = (state + 0x9E3779B97F4A7C15) & MASK
        z = state
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        z = z ^ (z >> 31)
        j = z % (i + 1)
        order[i], order[j] = order[j], order[i]
    return order


def words(text):
    return len(re.findall(r"[A-Za-z0-9’']+", text or ""))


def spread(values):
    return f"{min(values)} / {int(statistics.median(values))} / {max(values)}"


def positions(counter, n):
    return " · ".join(f"{'ABCD'[i]} {counter.get(i, 0)}" for i in range(n))


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--bible", default=os.path.join(CONTENT, "web.json"))
    ap.add_argument("--paths", default=os.path.join(CONTENT, "paths.json"))
    ap.add_argument("--lessons", action="store_true", help="also print one row per lesson")
    args = ap.parse_args(argv)
    with open(args.bible, encoding="utf-8") as f:
        bible = json.load(f)
    with open(args.paths, encoding="utf-8") as f:
        paths = json.load(f)["paths"]
    verses = {
        f"{b['abbrev']}.{c['number']}.{v['number']}": v["text"]
        for b in bible["books"]
        for c in b["chapters"]
        for v in c["verses"]
    }
    names = {b["abbrev"]: b["name"] for b in bible["books"]}

    print("| Path | Access | Lessons | Questions | Lesson words (min / median / max) | Scripture words (min / median / max) | Answer position, authored | Answer position, as displayed | Verse refs per book |")
    print("|---|---|---|---|---|---|---|---|---|")
    for p in paths:
        lessons = p["lessons"]
        quiz = [q for l in lessons for q in l["quiz"]]
        authored = Counter(q["correctIndex"] for q in quiz)
        shown = Counter(display_order(q).index(q["correctIndex"]) for q in quiz)
        width = max(len(q["choices"]) for q in quiz)
        books = Counter(r.split(".")[0] for l in lessons for r in l["verseRefs"])
        access = p.get("access", "free")
        if access == "premium":
            access += f", first {p.get('freePreviewLessons', 0)} free"
        if p.get("draft"):
            access += ", DRAFT"
        print(
            "| {} | {} | {} | {} | {} | {} | {} | {} | {} |".format(
                p["title"],
                access,
                len(lessons),
                len(quiz),
                spread([words(l["bodyMarkdown"]) for l in lessons]),
                spread([sum(words(verses.get(r)) for r in l["verseRefs"]) for l in lessons]),
                positions(authored, width),
                positions(shown, width),
                ", ".join(f"{names.get(b, b)} {n}" for b, n in books.most_common()),
            )
        )

    if args.lessons:
        for p in paths:
            print(f"\n**{p['title']}**\n")
            print("| Day | Id | Title | Passage | Lesson words | Scripture words | Questions |")
            print("|---|---|---|---|---|---|---|")
            for l in p["lessons"]:
                print(
                    "| {} | `{}` | {} | {} | {} | {} | {} |".format(
                        l["dayIndex"],
                        l["id"],
                        l["title"],
                        ", ".join(l["verseRefs"]),
                        words(l["bodyMarkdown"]),
                        sum(words(verses.get(r)) for r in l["verseRefs"]),
                        len(l["quiz"]),
                    )
                )


if __name__ == "__main__":
    main()
