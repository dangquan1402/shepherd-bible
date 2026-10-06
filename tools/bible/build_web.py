#!/usr/bin/env python3
r"""Build Shepherd's bundled Bible (Shepherd/Resources/Content/web.json) from eBible.org.

Source: the World English Bible, 66-book edition `engwebp` ("LORD"), USFM, from
https://ebible.org/Scriptures/engwebp_usfm.zip. The zip is pinned by SHA-256 below; a
different download is refused, so the bundle can only ever be a faithful copy of that file.

    python3 -I tools/bible/build_web.py            # download (or reuse cache), verify, write web.json
    python3 -I tools/bible/build_web.py --check    # rebuild in memory, fail unless web.json is byte-identical
                                                   # and every verse matches eBible's own VPL flattening

Conversion: verse text is the USFM text with markup removed (Strong's \w tags, footnotes \f,
cross references \x, character styles). Punctuation and spelling are untouched: the WEB may only
carry its name when the text, punctuation included, is unchanged (ebible.org/eng-web/webfaq.htm).
A psalm superscription (\d before verse 1) becomes the chapter's optional `heading` instead of
being folded into verse 1. Psalm 119's acrostic stanza names (ALEPH, BETH, ...) and Song of Songs
speaker labels (\sp) are not verse text and are dropped; the VPL cross-check allow-lists exactly
those verses (see VPL_EXPECTED_DIFFS).

Python 3.9+, stdlib only.
"""

import argparse
import hashlib
import io
import json
import os
import re
import sys
import urllib.request
import xml.etree.ElementTree as ET
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "Shepherd", "Resources", "Content", "web.json")
DIGEST = os.path.join(
    ROOT, "tools", "bible", "web.json.sha256"
)  # lets the validator detect edits offline
CACHE = os.path.join(ROOT, "tools", "bible", ".cache")

USFM_URL = "https://ebible.org/Scriptures/engwebp_usfm.zip"
USFM_SHA256 = "99ea438ef8a6a20a8122e1f1fa2b12da5504f6708c4b83bef98210ccf0533e12"
VPL_URL = "https://ebible.org/Scriptures/engwebp_vpl.zip"
VPL_SHA256 = "f02f675fcd002e6a4a65c4d79a1906b73754a5f366980bbb01fbc60fb39edc84"
USER_AGENT = (
    "shepherd-bible/build_web.py (+https://github.com/dangquan1402/shepherd-bible)"
)
SOURCE_DATE = (
    "2026-10-02"  # "source files dated 2 Oct 2026" on the eBible page for this zip
)

NT = {
    "MAT",
    "MRK",
    "LUK",
    "JHN",
    "ACT",
    "ROM",
    "1CO",
    "2CO",
    "GAL",
    "EPH",
    "PHP",
    "COL",
    "1TH",
    "2TH",
    "1TI",
    "2TI",
    "TIT",
    "PHM",
    "HEB",
    "JAS",
    "1PE",
    "2PE",
    "1JN",
    "2JN",
    "3JN",
    "JUD",
    "REV",
}
NON_CANON = {"FRT", "GLO", "INT", "BAK", "OTH"}
# Paragraph / poetry markers whose line may carry verse text.
TEXT_PARAS = {"p", "m", "mi", "nb", "b", "q1", "q2", "pi1", "li1"}
# Markers whose whole line is not verse text.
SKIP_LINES = {
    "id",
    "ide",
    "h",
    "toc1",
    "toc2",
    "toc3",
    "mt1",
    "mt2",
    "mt3",
    "ms1",
    "cl",
    "sp",
}

# Verses where eBible's VPL flattening differs from this conversion, beyond the psalm
# superscriptions (the VPL folds a chapter `heading` into verse 1; the cross-check applies that).
VPL_EXPECTED_DIFFS = {
    # Psalm 119 stanza names: the VPL puts ALEPH before verse 1 and each later name after the
    # last verse of the previous stanza (8, 16, ..., 168).
    "PSA.119.1",
    *(f"PSA.119.{8 * i}" for i in range(1, 22)),
    # Song of Songs speaker labels (\sp) that the VPL folds into the verse text.
    "SNG.1.4",
    "SNG.5.1",
    "SNG.6.13",
    "SNG.8.5",
    # Psalm 68:32: the USFM has "Lord—\qs Selah—\qs*"; the VPL adds a space before "Selah".
    "PSA.68.32",
}


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def fetch(url, expected_sha):
    """Return the pinned file's bytes, from the local cache or a fresh download."""
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, url.rsplit("/", 1)[1])
    if os.path.exists(path):
        with open(path, "rb") as f:
            data = f.read()
    else:
        print("downloading", url, file=sys.stderr)
        # eBible's CDN answers 403 to urllib's default User-Agent.
        req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
        with urllib.request.urlopen(req, timeout=120) as r:
            data = r.read()
    got = sha256(data)
    if got != expected_sha:
        sys.exit(
            f"SHA-256 mismatch for {url}\n  expected {expected_sha}\n  got      {got}\n"
            "eBible may have published a new revision. Review the change, update the pin, "
            "rebuild, and re-run tools/content/validate_content.py."
        )
    with open(path, "wb") as f:
        f.write(data)
    return data


def clean(s):
    s = re.sub(r"\\f .*?\\f\*", "", s, flags=re.DOTALL)
    s = re.sub(r"\\x .*?\\x\*", "", s, flags=re.DOTALL)
    s = re.sub(r"\\\+?w ([^|\\]*)\|[^\\]*\\\+?w\*", r"\1", s)
    s = re.sub(r"\\\+?[a-z]+[0-9]*\*", "", s)  # closing markers
    s = re.sub(
        r"\\\+?[a-z]+[0-9]* ?", "", s
    )  # opening markers eat their delimiter space
    return re.sub(r"[ \t\r\n]+", " ", s).strip(" ")


def convert_book(text):
    book_id = re.search(r"^\\id (\S+)", text, re.MULTILINE).group(1)
    name = re.search(r"^\\h (.+)$", text, re.MULTILINE).group(1).strip()
    chapters = []
    cur = None
    buf = []
    vnum = None

    def flush():
        nonlocal buf, vnum
        if cur is not None and vnum is not None:
            cur["verses"].append({"number": vnum, "text": clean(" ".join(buf))})
        buf = []
        vnum = None

    for line in text.splitlines():
        m = re.match(r"\\([a-z]+[0-9]*)\b ?(.*)$", line)
        marker, rest = (m.group(1), m.group(2)) if m else (None, line)
        if marker == "c":
            flush()
            cur = {"number": int(rest.split()[0]), "verses": []}
            chapters.append(cur)
            continue
        if marker in SKIP_LINES or cur is None:
            continue
        if marker == "d":
            if book_id == "PSA" and cur["number"] == 119:
                flush()  # acrostic stanza name (ALEPH, BETH, ...): ends the verse, is not verse text
            elif not cur["verses"] and vnum is None:
                cur["heading"] = clean(rest)  # psalm superscription
            else:
                raise ValueError(
                    f"{book_id} {cur['number']}: \\d after verse text: {line[:80]!r}"
                )
            continue
        if marker is not None and marker not in TEXT_PARAS and marker != "v":
            raise ValueError(
                f"{book_id}: unexpected USFM line marker \\{marker}: {line[:80]!r}"
            )
        body = line if marker == "v" else rest
        parts = re.split(r"\\v (\d+[a-z]?(?:-\d+)?) ", body)
        buf.append(parts[0])
        for i in range(1, len(parts), 2):
            flush()
            vnum = int(re.match(r"\d+", parts[i]).group())
            buf = [parts[i + 1]]
    flush()
    # A chapter-level key order that matches ContentModels.swift (number, heading?, verses).
    ordered = []
    for c in chapters:
        out = {"number": c["number"]}
        if "heading" in c:
            out["heading"] = c["heading"]
        out["verses"] = c["verses"]
        ordered.append(out)
    return book_id, name, ordered


def convert(usfm_zip):
    z = zipfile.ZipFile(io.BytesIO(usfm_zip))
    files = sorted(
        (n for n in z.namelist() if n.endswith(".usfm")),
        key=lambda n: int(os.path.basename(n).split("-")[0]),
    )
    books = []
    for n in files:
        text = z.read(n).decode("utf-8-sig")
        book_id = re.search(r"^\\id (\S+)", text, re.MULTILINE).group(1)
        if book_id in NON_CANON:
            continue
        book_id, name, chapters = convert_book(text)
        books.append(
            {
                "name": name,
                "abbrev": book_id,
                "order": len(books) + 1,
                "testament": "NT" if book_id in NT else "OT",
                "chapters": chapters,
            }
        )
    return {
        "translation": "WEB",
        "name": "World English Bible",
        "edition": "engwebp",
        "source": USFM_URL,
        "sourceSHA256": USFM_SHA256,
        "sourceDate": SOURCE_DATE,
        "license": 'Public domain. "World English Bible" is a trademark of eBible.org, used to identify this faithful copy.',
        "books": books,
    }


def serialize(bundle):
    return (
        json.dumps(bundle, ensure_ascii=False, separators=(",", ":")) + "\n"
    ).encode("utf-8")


def index(bundle):
    return {
        f"{b['abbrev']}.{c['number']}.{v['number']}": v["text"]
        for b in bundle["books"]
        for c in b["chapters"]
        for v in c["verses"]
    }


def cross_check_vpl(bundle, vpl_zip):
    """Compare every verse with eBible's VPL flattening of the same release."""
    z = zipfile.ZipFile(io.BytesIO(vpl_zip))
    root = ET.fromstring(z.read("engwebp_vpl.xml"))
    vpl = {
        "{}.{}.{}".format(v.get("b"), v.get("c"), v.get("v")): (v.text or "").strip()
        for v in root.iter("v")
    }
    ours = index(bundle)
    for b in bundle["books"]:
        for c in b["chapters"]:
            if "heading" in c:
                ref = f"{b['abbrev']}.{c['number']}.1"
                ours[ref] = c["heading"] + " " + ours[ref]
    problems = []
    for ref in sorted(set(vpl) - set(ours)):
        problems.append("only in VPL: " + ref)
    for ref in sorted(set(ours) - set(vpl)):
        problems.append("only in bundle: " + ref)
    differing = {r for r in set(ours) & set(vpl) if ours[r] != vpl[r]}
    for ref in sorted(differing - VPL_EXPECTED_DIFFS):
        problems.append(
            f"text differs from VPL: {ref}\n  bundle: {ours[ref]}\n  vpl   : {vpl[ref]}"
        )
    for ref in sorted(VPL_EXPECTED_DIFFS - differing):
        problems.append(
            "allow-listed difference no longer differs (update VPL_EXPECTED_DIFFS): "
            + ref
        )
    return len(ours), len(vpl), len(differing), problems


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument(
        "--check",
        action="store_true",
        help="verify the committed web.json instead of writing it",
    )
    args = ap.parse_args()

    bundle = convert(fetch(USFM_URL, USFM_SHA256))
    data = serialize(bundle)
    verses, vpl_count, differing, problems = cross_check_vpl(
        bundle, fetch(VPL_URL, VPL_SHA256)
    )
    print(
        f"{len(bundle['books'])} books, {verses} verses (VPL {vpl_count}, {differing} allow-listed differences),"
        f" {len(data)} bytes, sha256 {sha256(data)}"
    )
    for p in problems:
        print("ERROR", p)
    if problems:
        sys.exit(1)

    if args.check:
        with open(OUT, "rb") as f:
            committed = f.read()
        if committed != data:
            sys.exit(
                "ERROR web.json is not the faithful conversion of the pinned source; run build_web.py"
            )
        with open(DIGEST, encoding="utf-8") as f:
            if f.read().split()[0] != sha256(data):
                sys.exit("ERROR web.json.sha256 is stale; run build_web.py")
        print(
            "OK web.json is byte-identical to the conversion of the pinned eBible source"
        )
    else:
        with open(OUT, "wb") as f:
            f.write(data)
        with open(DIGEST, "w", encoding="utf-8") as f:
            f.write(f"{sha256(data)}  web.json\n")
        print("wrote", os.path.relpath(OUT, ROOT), "and", os.path.relpath(DIGEST, ROOT))


if __name__ == "__main__":
    main()
