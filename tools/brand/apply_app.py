"""Write the Flock brand into the app: colour sets, lamb geometry, app icon, tab glyph, wordmark + mark.

    python3 tools/brand/apply_app.py

Needs shapely and resvg_py (for the 1024 px icon PNGs). Everything is derived from tools/brand/:
tokens.py (colours), lambgen.py (lamb, avatars, glyph, front face), brandart.py (icon), wordmark.json.
"""

from __future__ import annotations

import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import brandart
import lambgen
import tokens as T

ROOT = os.path.dirname(os.path.dirname(HERE))
XC = os.path.join(ROOT, "Shepherd/Resources/Assets.xcassets")
DIRECTION = "flock"
SPECIAL = {"--color-accent": "AccentColor"}
NEW_ASSETS = {
    "--color-mascot-legs",
    "--color-mascot-eye-white",
    "--color-mascot-mouth",
    "--color-mascot-flower",
    "--color-mascot-zz",
    "--color-highlight-yellow-swatch",
    "--color-highlight-blue-swatch",
    "--color-highlight-purple-swatch",
    "--color-highlight-rose-swatch",
    "--color-highlight-amber-swatch",
}
INFO = {"author": "xcode", "version": 1}


def asset_name(token):
    if token in SPECIAL:
        return SPECIAL[token]
    return "".join(p.capitalize() for p in token.removeprefix("--color-").split("-"))


def comps(hexv):
    h = hexv.lstrip("#")
    r, g, b = (int(h[i : i + 2], 16) / 255 for i in (0, 2, 4))
    a = int(h[6:8], 16) / 255 if len(h) == 8 else 1.0
    return {"alpha": f"{a:.3f}", "blue": f"{b:.3f}", "green": f"{g:.3f}", "red": f"{r:.3f}"}


def colorset(light, dark):
    return {
        "colors": [
            {"color": {"color-space": "srgb", "components": comps(light)}, "idiom": "universal"},
            {
                "appearances": [{"appearance": "luminosity", "value": "dark"}],
                "color": {"color-space": "srgb", "components": comps(dark)},
                "idiom": "universal",
            },
        ],
        "info": INFO,
    }


def write_json(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")


def colors():
    n = 0
    for token, (light, dark) in T.tokens(DIRECTION).items():
        name = asset_name(token)
        path = os.path.join(XC, f"{name}.colorset")
        if os.path.isdir(path) or token in NEW_ASSETS:
            write_json(os.path.join(path, "Contents.json"), colorset(light, dark))
            n += 1
    return n


def lamb():
    data = lambgen.build_all(DIRECTION)
    data.pop("style", None)
    with open(os.path.join(ROOT, "Shepherd/Resources/Content/lamb_variants.json"), "w") as f:
        json.dump(data, f, separators=(",", ":"))
    return data


def app_icon():
    d = os.path.join(XC, "AppIcon.appiconset")
    files = {"default": "AppIcon.png", "dark": "AppIcon-Dark.png", "tinted": "AppIcon-Tinted.png"}
    for app, fn in files.items():
        brandart.render(brandart.icon_svg(DIRECTION, app), os.path.join(d, fn))
    images = [{"filename": files["default"], "idiom": "universal", "platform": "ios", "size": "1024x1024"}]
    for app in ("dark", "tinted"):
        images.append(
            {
                "appearances": [{"appearance": "luminosity", "value": app}],
                "filename": files[app],
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024",
            }
        )
    write_json(os.path.join(d, "Contents.json"), {"images": images, "info": INFO})


def svg_doc(w, h, vb, body):
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{w:g}" height="{h:g}" '
        f'viewBox="{vb[0]:g} {vb[1]:g} {vb[2]:g} {vb[3]:g}">{body}</svg>\n'
    )


def tab_glyph(data):
    g = data["glyph"]
    vx, vy, vw, vh = g["viewBox"]
    k = 20.0 / max(vw, vh)
    tw, th = vw * k, vh * k
    body = (
        f'<g transform="translate({(24 - tw) / 2:.4f},{(24 - th) / 2:.4f}) scale({k:.6f}) '
        f'translate({-vx:.4f},{-vy:.4f})"><path d="{g["geometry"]}" fill="#000000"/></g>'
    )
    with open(os.path.join(XC, "TabLamb.imageset/tab_lamb.svg"), "w") as f:
        f.write(svg_doc(24, 24, (0, 0, 24, 24), body))


def wordmark():
    """Template vector (tinted in code with the accent token)."""
    with open(os.path.join(HERE, "wordmark.json")) as f:
        w = json.load(f)
    mx, my, mw, mh = w["bbox"]
    d = os.path.join(XC, "Wordmark.imageset")
    os.makedirs(d, exist_ok=True)
    h = 30.0
    with open(os.path.join(d, "wordmark.svg"), "w") as f:
        f.write(svg_doc(round(mw * h / mh, 2), h, (mx, my, mw, mh), f'<path d="{w["d"]}" fill="#000000"/>'))
    write_json(
        os.path.join(d, "Contents.json"),
        {
            "images": [{"filename": "wordmark.svg", "idiom": "universal"}],
            "info": INFO,
            "properties": {"preserves-vector-representation": True, "template-rendering-intent": "template"},
        },
    )


def brand_mark():
    """Full-colour vector mark (the face on the accent chip), light and dark."""
    d = os.path.join(XC, "BrandMark.imageset")
    os.makedirs(d, exist_ok=True)
    for mode, fn in (("light", "brand_mark.svg"), ("dark", "brand_mark_dark.svg")):
        t = T.tokens(DIRECTION)
        chip = t["--color-accent-fill"][0 if mode == "light" else 1]
        body = f'<circle cx="20" cy="20" r="20" fill="{chip}"/>' + re.sub(
            r"^<circle[^>]*/>", "", brandart.mark_svg(DIRECTION, 40, True, mode)
        )
        with open(os.path.join(d, fn), "w") as f:
            f.write(svg_doc(40, 40, (0, 0, 40, 40), body))
    write_json(
        os.path.join(d, "Contents.json"),
        {
            "images": [
                {"filename": "brand_mark.svg", "idiom": "universal"},
                {
                    "appearances": [{"appearance": "luminosity", "value": "dark"}],
                    "filename": "brand_mark_dark.svg",
                    "idiom": "universal",
                },
            ],
            "info": INFO,
            "properties": {"preserves-vector-representation": True},
        },
    )


if __name__ == "__main__":
    n = colors()
    data = lamb()
    app_icon()
    tab_glyph(data)
    wordmark()
    brand_mark()
    print(
        f"colour sets: {n}; lamb: {sum(len(s['expressions']) for s in data['stages'].values())} variants, "
        f"{len(data['avatars'])} avatars; app icon: default/dark/tinted; TabLamb, Wordmark, BrandMark"
    )
