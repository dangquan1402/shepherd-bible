"""Icon check sheet from the BUILT app: its AppIcon renditions at 60 / 40 / 29 pt on four home screens.

    python3 tools/brand/icon_check.py <path/to/Shepherd.app> <out.png> [home-screen screenshots ...]

Reads the compiled bundle: `assetutil --info Assets.car` must list the default, dark (UIAppearanceDark)
and tinted (ISAppearanceTintable) AppIcon renditions, and their rendition files are taken from the
asset catalog the bundle was built from. The bundle's loose AppIcon60x60@2x.png (actool output) is
shown at 1:1 as the 60 pt default. Tinted is the system tint applied to the grayscale source; clear
is white luminance over a blurred wallpaper (an approximation of iOS 26 clear). Real simulator
home-screen screenshots, when given, are appended below the mockups.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SET = os.path.join(ROOT, "Shepherd/Resources/Assets.xcassets/AppIcon.appiconset")
SF = "/System/Library/Fonts/SFNS.ttf"


def font(size):
    return ImageFont.truetype(SF, size)


def squircle(img, px):
    img = img.convert("RGBA").resize((px, px), Image.LANCZOS)
    m = Image.new("L", (px * 4, px * 4), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, px * 4 - 1, px * 4 - 1], radius=int(px * 4 * 0.2237), fill=255)
    img.putalpha(m.resize((px, px), Image.LANCZOS))
    return img


def renditions(app):
    out = subprocess.run(
        ["xcrun", "--sdk", "iphonesimulator", "assetutil", "--info", os.path.join(app, "Assets.car")],
        capture_output=True,
        text=True,
        check=True,
    ).stdout
    found = {}
    for r in json.loads(out):
        if r.get("Name") == "AppIcon" and r.get("AssetType") == "Icon Image":
            found[r.get("Appearance") or "default"] = r["RenditionName"]
    need = {"default", "UIAppearanceDark", "ISAppearanceTintable"}
    missing = need - set(found)
    if missing:
        sys.exit(f"built Assets.car is missing AppIcon appearances: {sorted(missing)}")
    return {
        "default": Image.open(os.path.join(SET, found["default"])),
        "dark": Image.open(os.path.join(SET, found["UIAppearanceDark"])),
        "tinted": Image.open(os.path.join(SET, found["ISAppearanceTintable"])),
    }


def wallpaper(w, h, top, bot):
    g = Image.new("RGB", (1, 256))
    for i in range(256):
        t = i / 255
        g.putpixel((0, i), tuple(round(top[c] * (1 - t) + bot[c] * t) for c in range(3)))
    return g.resize((w, h)).convert("RGBA")


KINDS = {
    "default": ((214, 228, 244), (246, 232, 218), (20, 20, 20)),
    "dark": ((20, 24, 33), (44, 49, 64), (240, 240, 240)),
    "clear": ((88, 132, 206), (226, 150, 116), (250, 250, 250)),
    "tinted": ((26, 30, 38), (40, 44, 56), (240, 240, 240)),
}


def mock(kind, icons, loose):
    top, bot, lab = KINDS[kind]
    wp = wallpaper(700, 330, top, bot)
    dr = ImageDraw.Draw(wp)
    if kind == "default":
        ic = icons["default"]
    elif kind == "dark":
        ic = icons["dark"]
    elif kind == "tinted":
        ic = ImageOps.colorize(icons["tinted"].convert("L"), black="#05070A", white="#9CC3FF")
    else:
        lum = icons["tinted"].convert("L")
        base = wp.filter(ImageFilter.GaussianBlur(18)).resize(lum.size)
        ic = Image.alpha_composite(base, Image.new("RGBA", lum.size, (255, 255, 255, 50)))
        ic.paste(Image.new("RGBA", lum.size, (255, 255, 255, 235)), (0, 0), lum.point(lambda v: min(255, v * 1.15)))
    x = 40
    for pt in (60, 40, 29):
        px = pt * 3
        src = loose if (kind == "default" and pt == 40) else ic  # actool's own 120 px default, 1:1 at 40 pt @3x
        wp.alpha_composite(squircle(src, px), (x, 60 + 180 - px))
        dr.text((x + px / 2, 270), "Shepherd" if pt == 60 else f"{pt} pt", font=font(26), fill=lab, anchor="mm")
        x += px + 40
    dr.text((24, 18), f"{kind} appearance", font=font(24), fill=lab)
    return wp


def main():
    app, out = sys.argv[1], sys.argv[2]
    shots = sys.argv[3:]
    icons = renditions(app)
    loose = Image.open(os.path.join(app, "AppIcon60x60@2x.png"))
    mocks = [mock(k, icons, loose) for k in KINDS]
    W = 2 * 700 + 60
    shot_imgs = [Image.open(s).convert("RGB") for s in shots]
    sh = 0
    if shot_imgs:
        k = (W - 40 - 20 * (len(shot_imgs) - 1)) / sum(i.width for i in shot_imgs)
        shot_imgs = [i.resize((int(i.width * k), int(i.height * k))) for i in shot_imgs]
        sh = shot_imgs[0].height + 70
    H = 90 + 2 * 350 + sh
    sheet = Image.new("RGB", (W, H), "#F2F2F4")
    dr = ImageDraw.Draw(sheet)
    dr.text((20, 24), "Built app icon (Assets.car: default, dark, tinted) at 60 / 40 / 29 pt", font=font(34), fill="#111")
    for i, m in enumerate(mocks):
        sheet.paste(m.convert("RGB"), (20 + (i % 2) * 720, 90 + (i // 2) * 350))
    if shot_imgs:
        y = 90 + 2 * 350 + 10
        dr.text((20, y), "Simulator home screen (real system rendering)", font=font(28), fill="#111")
        x = 20
        for s in shot_imgs:
            sheet.paste(s, (x, y + 50))
            x += s.width + 20
    sheet.save(out, optimize=True)
    print(out)


if __name__ == "__main__":
    main()
