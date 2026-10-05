"""Before/after boards for the brand change: design export and real app, master vs this branch.

    python3 tools/brand/before_after.py [base-ref]      # default base: master; writes docs/brand/before_after_*.png
"""

from __future__ import annotations

import io
import os
import subprocess
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "docs/brand")
SCREENS = ["Onboarding_Welcome", "Home_DailyPath", "Quiz_Wrong", "Lesson_Complete", "Companion_Detail", "Paywall_Trial"]
SF = "/System/Library/Fonts/SFNS.ttf"
W = 300  # column width


def at_ref(ref, path):
    data = subprocess.run(["git", "show", f"{ref}:{path}"], cwd=ROOT, capture_output=True, check=True).stdout
    return Image.open(io.BytesIO(data)).convert("RGB")


def now(path):
    return Image.open(os.path.join(ROOT, path)).convert("RGB")


def fit(im):
    return im.resize((W, round(im.height * W / im.width)), Image.LANCZOS)


def board(mode, base):
    cols = [
        ("Design · before", lambda n: at_ref(base, f"design/exports/{n}_{mode}.png")),
        ("Design · after", lambda n: now(f"design/exports/{n}_{mode}.png")),
        ("App · before", lambda n: at_ref(base, f"docs/screenshots/{n}_{mode}.png")),
        ("App · after", lambda n: now(f"docs/screenshots/{n}_{mode}.png")),
    ]
    rows = [[fit(get(n)) for _, get in cols] for n in SCREENS]
    rh = max(im.height for r in rows for im in r)
    gap, top, left = 16, 70, 210
    img = Image.new("RGB", (left + 4 * (W + gap), top + len(rows) * (rh + gap)), "#1C1C1E")
    dr = ImageDraw.Draw(img)
    f, fs = ImageFont.truetype(SF, 26), ImageFont.truetype(SF, 20)
    for c, (label, _) in enumerate(cols):
        dr.text((left + c * (W + gap) + W / 2, 36), label, font=f, fill="#F2F2F7", anchor="mm")
    for r, (name, ims) in enumerate(zip(SCREENS, rows)):
        y = top + r * (rh + gap)
        dr.text((16, y + rh / 2), name.replace("_", "\n"), font=fs, fill="#C7C7CC", anchor="lm")
        for c, im in enumerate(ims):
            img.paste(im, (left + c * (W + gap), y))
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, f"before_after_{mode.lower()}.png")
    img.save(path, optimize=True)
    return path


if __name__ == "__main__":
    base = sys.argv[1] if len(sys.argv) > 1 else "master"
    for mode in ("Light", "Dark"):
        print(board(mode, base))
