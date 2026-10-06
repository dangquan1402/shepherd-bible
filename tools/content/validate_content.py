#!/usr/bin/env python3
"""Validate Shepherd's lesson content against the bundled World English Bible.

    python3 -I tools/content/validate_content.py            # shipped paths.json vs web.json
    python3 -I tools/content/validate_content.py --release  # also fail on draft paths
    python3 -I tools/content/validate_content.py --paths other.json --bible other_bible.json

Exit status 1 on any ERROR. What it proves is textual: every reference exists, every quotation
is verbatim WEB text, every answer is in the verse the app shows as proof. It cannot judge an
interpretation, a distractor's tone or a study aid's history; that is the human review's job.

Python 3.9+, stdlib only.
"""

import argparse
import hashlib
import json
import os
import re
import sys
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CONTENT = os.path.join(ROOT, "Shepherd", "Resources", "Content")

EDITION = "engwebp"
# Must equal USFM_SHA256 in tools/bible/build_web.py (the test suite checks they agree).
SOURCE_SHA256 = "99ea438ef8a6a20a8122e1f1fa2b12da5504f6708c4b83bef98210ccf0533e12"

BIBLE_DIGEST = os.path.join(ROOT, "tools", "bible", "web.json.sha256")

REF = re.compile(r"^([1-3]?[A-Z]{2,3})\.(\d+)\.(\d+)$")
# Quotations may be delimited with straight "…" or typographic “…” marks; both are checked.
QUOTE = re.compile(r'["“]([^"“”]+)["”]')
BLANK = "___"
MIN_QUOTE = 12  # shorter quoted strings are single words ("yoke"), not verse text
ACCESS = {"free", "premium", "seasonal"}
GOALS = {"grow_daily", "understand", "peace"}
LEVELS = {"beginner", "some", "deep"}


def index(bible):
    return {
        f"{b['abbrev']}.{c['number']}.{v['number']}": v["text"]
        for b in bible["books"]
        for c in b["chapters"]
        for v in c["verses"]
    }


def prose_ref_pattern(bible):
    names = {b["name"]: b["abbrev"] for b in bible["books"]}
    names["Psalm"] = "PSA"
    alternation = "|".join(sorted((re.escape(n) for n in names), key=len, reverse=True))
    return names, re.compile(rf"\b({alternation}) (\d+):(\d+)")


def display(ref, abbrev_names):
    m = REF.match(ref)
    return (
        f"{abbrev_names.get(m.group(1), m.group(1))} {m.group(2)}:{m.group(3)}"
        if m
        else ref
    )


def bible_digest_error(data):
    """The bundled Bible must be byte-identical to what tools/bible/build_web.py generated."""
    with open(BIBLE_DIGEST, encoding="utf-8") as f:
        expected = f.read().split()[0]
    got = hashlib.sha256(data).hexdigest()
    if got != expected:
        return f"bible: web.json (sha256 {got[:12]}) is not the file build_web.py generated ({expected[:12]}); it was edited by hand"
    return None


def validate(bible, bundle, release=False):
    errs, warns = [], []
    verses = index(bible)
    names, prose_ref = prose_ref_pattern(bible)
    abbrev_names = {b["abbrev"]: b["name"] for b in bible["books"]}
    abbrev_names["PSA"] = "Psalm"

    if bible.get("edition") != EDITION:
        errs.append(
            "bible: edition is {!r}, expected {!r}".format(
                bible.get("edition"), EDITION
            )
        )
    if bible.get("sourceSHA256") != SOURCE_SHA256:
        errs.append(
            "bible: sourceSHA256 does not match the pinned eBible source; rebuild with tools/bible/build_web.py"
        )

    def cited(text):
        refs = []
        for book, c, v in prose_ref.findall(text or ""):
            refs.append((f"{book} {c}:{v}", f"{names[book]}.{c}.{v}"))
        return refs

    seen = set()
    path_ids = set()
    for p in bundle.get("paths", []):
        pid = p.get("id", "?")
        if pid in path_ids:
            errs.append(f"{pid}: duplicate path id")
        path_ids.add(pid)
        lessons = p.get("lessons", [])

        access = p.get("access", "free")
        if access not in ACCESS:
            errs.append(f"{pid}: access {access!r} is not one of {sorted(ACCESS)}")
        preview = p.get("freePreviewLessons")
        if access == "premium":
            if not isinstance(preview, int) or not 0 <= preview <= len(lessons):
                errs.append(
                    f"{pid}: premium path needs freePreviewLessons in 0...{len(lessons)}, got {preview!r}"
                )
        elif preview is not None:
            errs.append(f"{pid}: freePreviewLessons only applies to premium paths")
        for key, allowed in (("goals", GOALS), ("levels", LEVELS)):
            bad = set(p.get(key, [])) - allowed
            if bad:
                errs.append(f"{pid}: unknown {key} {sorted(bad)}")

        draft = p.get("draft")
        if draft is not None:
            planned = draft.get("plannedLessons")
            msg = f"{pid}: draft path, {len(lessons)} of {planned} lessons written"
            (errs if release else warns).append(
                msg + (" (a release build must not ship drafts)" if release else "")
            )
            if p.get("estimatedDays") != planned:
                errs.append(
                    "{}: estimatedDays {!r} != draft.plannedLessons {!r}".format(
                        pid, p.get("estimatedDays"), planned
                    )
                )
        elif p.get("estimatedDays") != len(lessons):
            errs.append(
                f"{pid}: estimatedDays {p.get('estimatedDays')!r} != {len(lessons)} lessons"
            )

        days = [lesson.get("dayIndex") for lesson in lessons]
        if days != list(range(1, len(days) + 1)):
            errs.append(f"{pid}: dayIndex is not 1...n: {days}")

        positions = [
            q.get("correctIndex") for lesson in lessons for q in lesson.get("quiz", [])
        ]
        if len(positions) >= 4:
            counts = Counter(positions)
            top, n = counts.most_common(1)[0]
            if len(counts) == 1:
                errs.append(
                    f"{pid}: all {n} answers are choice #{top}; the answer position leaks"
                )
            elif n * 2 > len(positions):
                warns.append(
                    f"{pid}: {n} of {len(positions)} answers are choice #{top}"
                )

        for lesson in lessons:
            lid = "{}/{}".format(pid, lesson.get("id"))
            if lesson.get("id") in seen:
                errs.append(
                    f"{lid}: duplicate lesson id (progress is keyed by lesson id alone)"
                )
            seen.add(lesson.get("id"))

            refs = lesson.get("verseRefs") or []
            if not refs:
                errs.append(f"{lid}: no verseRefs")
            for r in refs:
                if not REF.match(r):
                    errs.append(f"{lid}: malformed ref {r!r}")
                elif r not in verses:
                    errs.append(f"{lid}: {r} does not exist in the bundled WEB")

            quiz = lesson.get("quiz") or []
            texts = [lesson.get("bodyMarkdown"), lesson.get("prayerPrompt")]
            texts += [q.get("explain") for q in quiz] + [q.get("prompt") for q in quiz]
            pool = {r for r in refs if r in verses}
            for t in texts:
                for label, r in cited(t):
                    if r not in verses:
                        errs.append(f"{lid}: prose cites {label}, which does not exist")
                    else:
                        pool.add(r)
            for t in texts:
                for quoted in QUOTE.findall(t or ""):
                    if BLANK in quoted or len(quoted) < MIN_QUOTE:
                        continue
                    needle = quoted.rstrip(".,;:")
                    if not any(needle in verses[r] for r in pool):
                        errs.append(
                            f'{lid}: quotation is not verbatim WEB text from its verses: "{quoted}"'
                        )

            for q in quiz:
                qid = "{}/{}".format(lid, q.get("id"))
                if q.get("id") in seen:
                    errs.append(f"{qid}: duplicate question id")
                seen.add(q.get("id"))
                choices = q.get("choices") or []
                ci = q.get("correctIndex")
                if len(choices) < 2:
                    errs.append(f"{qid}: needs at least 2 choices")
                if len({c.lower() for c in choices}) != len(choices):
                    errs.append(f"{qid}: duplicate choices")
                if not isinstance(ci, int) or not 0 <= ci < len(choices):
                    errs.append(
                        f"{qid}: correctIndex {ci!r} is out of range for {len(choices)} choices"
                    )
                    continue
                answer = choices[ci]

                ar = q.get("answerRef")
                if not ar:
                    errs.append(
                        f"{qid}: no answerRef (the proof verse shown after answering)"
                    )
                    continue
                if ar not in verses:
                    errs.append(
                        f"{qid}: answerRef {ar} does not exist in the bundled WEB"
                    )
                    continue
                if ar not in refs:
                    errs.append(
                        f"{qid}: answerRef {ar} is not one of the lesson's verses {refs}"
                    )
                proof = verses[ar]
                if answer.lower() not in proof.lower():
                    errs.append(
                        f"{qid}: answer {answer!r} is not in its proof verse {ar}: {proof}"
                    )
                for i, c in enumerate(choices):
                    if i != ci and len(c) > 3 and c.lower() in proof.lower():
                        warns.append(
                            f"{qid}: wrong choice {c!r} also appears in the proof verse {ar}"
                        )

                for quoted in QUOTE.findall(q.get("prompt") or ""):
                    if BLANK in quoted:
                        filled = quoted.replace(BLANK, answer).rstrip(".,;:")
                        if filled not in proof:
                            errs.append(
                                f'{qid}: blank filled with the answer is not in {ar}: "{filled}"'
                            )

                explain = q.get("explain")
                if not explain:
                    errs.append(f"{qid}: no explain text")
                elif ar not in {r for _, r in cited(explain)}:
                    errs.append(
                        f"{qid}: explain does not cite its proof verse {display(ar, abbrev_names)}"
                    )

    return errs, warns


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--bible", default=os.path.join(CONTENT, "web.json"))
    ap.add_argument("--paths", default=os.path.join(CONTENT, "paths.json"))
    ap.add_argument(
        "--release", action="store_true", help="treat draft paths as errors"
    )
    args = ap.parse_args(argv)
    with open(args.bible, "rb") as f:
        data = f.read()
    bible = json.loads(data.decode("utf-8"))
    with open(args.paths, encoding="utf-8") as f:
        bundle = json.load(f)
    errs, warns = validate(bible, bundle, release=args.release)
    digest = bible_digest_error(data)
    if digest:
        errs.insert(0, digest)
    for e in errs:
        print("ERROR", e)
    for w in warns:
        print("WARN ", w)
    paths = bundle.get("paths", [])
    print(
        f"summary: {len(errs)} errors, {len(warns)} warnings, {len(paths)} paths,"
        f" {sum(len(p.get('lessons', [])) for p in paths)} lessons"
    )
    return 1 if errs else 0


if __name__ == "__main__":
    sys.exit(main())
