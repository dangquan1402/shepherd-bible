"""Tests for validate_content.py: the shipped content passes, and each defect class fails.

python3 -I -m unittest discover -s tools/content -v
"""

import copy
import json
import os
import re
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import validate_content as vc

with open(os.path.join(vc.CONTENT, "web.json"), "rb") as f:
    BIBLE_BYTES = f.read()
BIBLE = json.loads(BIBLE_BYTES.decode("utf-8"))
with open(os.path.join(vc.CONTENT, "paths.json"), encoding="utf-8") as f:
    PATHS = json.load(f)


def lesson(bundle, lesson_id):
    return next(
        l for p in bundle["paths"] for l in p["lessons"] if l["id"] == lesson_id
    )


def question(bundle, qid):
    return next(
        q
        for p in bundle["paths"]
        for l in p["lessons"]
        for q in l["quiz"]
        if q["id"] == qid
    )


def errors(bundle, bible=BIBLE, release=False):
    return vc.validate(bible, bundle, release=release)[0]


class ShippedContent(unittest.TestCase):
    def test_shipped_content_has_no_errors(self):
        self.assertEqual(errors(PATHS), [])

    def test_shipped_content_is_release_ready(self):
        # The three launch paths are complete: no path may still be marked draft.
        self.assertEqual(errors(PATHS, release=True), [])
        self.assertEqual(
            {p["id"]: len(p["lessons"]) for p in PATHS["paths"]},
            {"beginner-30": 30, "peace-14": 14, "mark-30": 30},
        )

    def test_pinned_source_hash_matches_the_bible_builder(self):
        with open(
            os.path.join(vc.ROOT, "tools", "bible", "build_web.py"), encoding="utf-8"
        ) as f:
            pinned = re.search(r'USFM_SHA256 = "([0-9a-f]{64})"', f.read()).group(1)
        self.assertEqual(pinned, vc.SOURCE_SHA256)

    def test_bundle_is_the_whole_66_book_bible(self):
        self.assertEqual(len(BIBLE["books"]), 66)
        self.assertEqual(len(vc.index(BIBLE)), 31103)
        self.assertEqual(
            vc.index(BIBLE)["PSA.23.1"],
            "The LORD is my shepherd; I shall lack nothing.",
        )


class DefectsAreCaught(unittest.TestCase):
    """Each test reintroduces one defect into a copy and expects a matching ERROR."""

    def assertCaught(self, bundle, pattern, **kw):
        errs = errors(bundle, **kw)
        self.assertTrue(
            any(re.search(pattern, e) for e in errs),
            f"no error matching {pattern!r} in {errs}",
        )

    def mutated(self):
        return copy.deepcopy(PATHS)

    def test_nonexistent_verse_ref(self):
        b = self.mutated()
        lesson(b, "day1")["verseRefs"].append("GEN.1.99")
        self.assertCaught(b, r"day1: GEN\.1\.99 does not exist")

    def test_nonexistent_prose_citation(self):
        b = self.mutated()
        l = lesson(b, "mark-30.d02")
        l["bodyMarkdown"] = l["bodyMarkdown"].replace("Mark 3:16", "Mark 3:96")
        self.assertCaught(b, r"prose cites Mark 3:96, which does not exist")

    def test_straight_apostrophe_in_quoted_verse_text(self):
        b = self.mutated()
        q = question(b, "day2-q1")
        q["explain"] = q["explain"].replace("God’s", "God's")
        self.assertCaught(b, r"day2: quotation is not verbatim WEB text")

    def test_misquote_in_lesson_prose(self):
        b = self.mutated()
        l = lesson(b, "peace-14.d01")
        l["bodyMarkdown"] = l["bodyMarkdown"].replace("heavily burdened", "heavy laden")
        self.assertCaught(
            b,
            r"peace-14\.d01: quotation is not verbatim WEB text from its verses: \"Come to me, all you who labor and are heavy laden",
        )

    def test_hand_edited_bible_text(self):
        # The old sample Bible dropped the opening quotation mark of Matthew 5:14.
        self.assertIsNone(vc.bible_digest_error(BIBLE_BYTES))
        edited = BIBLE_BYTES.replace(
            "“You are the light of the world.".encode(),
            b"You are the light of the world.",
            1,
        )
        self.assertNotEqual(edited, BIBLE_BYTES)
        self.assertRegex(
            vc.bible_digest_error(edited), r"web\.json .* was edited by hand"
        )

    def test_correct_index_out_of_range(self):
        b = self.mutated()
        question(b, "day3-q1")["correctIndex"] = 4
        self.assertCaught(b, r"day3-q1: correctIndex 4 is out of range")

    def test_answer_not_in_proof_verse(self):
        # The shipped day7-q3 said "Hearts and thoughts"; Philippians 4:7 says "hearts and your thoughts".
        b = self.mutated()
        q = question(b, "day7-q3")
        q["choices"][q["correctIndex"]] = "Hearts and thoughts"
        self.assertCaught(
            b,
            r"day7-q3: answer 'Hearts and thoughts' is not in its proof verse PHP\.4\.7",
        )

    def test_wrong_proof_verse(self):
        b = self.mutated()
        question(b, "day7-q3")["answerRef"] = "MAT.6.9"
        self.assertCaught(b, r"day7-q3: answer .* is not in its proof verse MAT\.6\.9")

    def test_proof_verse_not_shown_in_lesson(self):
        b = self.mutated()
        question(b, "day1-q1")["answerRef"] = "GEN.1.2"
        self.assertCaught(
            b, r"day1-q1: answerRef GEN\.1\.2 is not one of the lesson's verses"
        )

    def test_explain_must_cite_the_proof_verse(self):
        b = self.mutated()
        question(b, "mark-30.d02.q1")["explain"] = "They were fishermen, at work."
        self.assertCaught(
            b, r"mark-30\.d02\.q1: explain does not cite its proof verse Mark 1:16"
        )

    def test_fill_in_the_blank_must_be_verbatim(self):
        b = self.mutated()
        question(b, "peace-14.d01.q3")["prompt"] = (
            '"My yoke is easy, and my burden is ___."'
        )
        self.assertCaught(
            b, r"peace-14\.d01\.q3: blank filled with the answer is not in MAT\.11\.30"
        )

    def test_all_answers_in_the_same_position(self):
        b = self.mutated()
        for l in b["paths"][0]["lessons"]:
            for q in l["quiz"]:
                answer = q["choices"].pop(q["correctIndex"])
                q["choices"].insert(0, answer)
                q["correctIndex"] = 0
        self.assertCaught(b, r"beginner-30: all \d+ answers are choice #0")

    def test_lord_edition_wording(self):
        # The Classic WEB says "Yahweh is my shepherd"; the bundled engwebp says "The LORD".
        b = self.mutated()
        q = question(b, "day5-q1")
        q["explain"] = 'Psalm 23:1: "Yahweh is my shepherd; I shall lack nothing."'
        self.assertCaught(b, r"day5: quotation is not verbatim WEB text")

    def test_duplicate_lesson_id_across_paths(self):
        b = self.mutated()
        lesson(b, "peace-14.d01")["id"] = "day1"
        self.assertCaught(b, r"peace-14/day1: duplicate lesson id")

    def test_premium_path_needs_preview_count(self):
        b = self.mutated()
        del b["paths"][1]["freePreviewLessons"]
        self.assertCaught(b, r"peace-14: premium path needs freePreviewLessons")

    def test_drafts_fail_a_release_check(self):
        b = self.mutated()
        p = b["paths"][1]
        n = len(p["lessons"])
        p["draft"] = {"plannedLessons": n + 1}
        p["estimatedDays"] = n + 1
        self.assertEqual(errors(b), [])
        self.assertCaught(
            b, rf"peace-14: draft path, {n} of {n + 1} lessons written", release=True
        )

    def test_bible_from_another_source(self):
        bible = dict(BIBLE, sourceSHA256="0" * 64)
        self.assertCaught(PATHS, r"sourceSHA256 does not match", bible=bible)


if __name__ == "__main__":
    unittest.main()
