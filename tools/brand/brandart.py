"""Brand art for a direction: outlined wordmark, logo mark, app icon (default / dark / clear / tinted).

Needs: shapely, fonttools, uharfbuzz, resvg_py, pillow. Fonts (all SIL OFL 1.1) are read from --fonts.

    python3 tools/brand/brandart.py <direction> --fonts <dir> --out <dir>
"""
from __future__ import annotations

import argparse
import base64
import io
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lambgen  # noqa: E402
import tokens as T  # noqa: E402

# ------------------------------------------------------------------ wordmarks

WORDMARKS = {
    # Fraunces: soft, slightly wonky old-style serif. SOFT 100 rounds every terminal.
    "dayspring": dict(font="fraunces_Fraunces[SOFT,WONK,opsz,wght].ttf", text="Shepherd",
                      axes={"wght": 640, "opsz": 72, "SOFT": 100, "WONK": 1}, tracking=-0.012,
                      licence="Fraunces, SIL Open Font License 1.1 (Undercase Type)"),
    # Baloo 2 ExtraBold: chunky, rounded, lowercase; the mascot-brand voice.
    "flock": dict(font="baloo2_Baloo2[wght].ttf", text="shepherd", axes={"wght": 800}, tracking=-0.018,
                  licence="Baloo 2, SIL Open Font License 1.1 (Ek Type)"),
    # Cormorant Garamond SemiBold, spaced capitals: a quiet psalter title.
    "still": dict(font="cormorantgaramond_CormorantGaramond[wght].ttf", text="SHEPHERD", axes={"wght": 600},
                  tracking=0.16, licence="Cormorant Garamond, SIL Open Font License 1.1 (Christian Thalmann)"),
}


def wordmark(direction, fonts_dir):
    """Return (svg path d, [minx, miny, w, h]) of the outlined wordmark at 100 units per em."""
    import uharfbuzz as hb
    from fontTools.pens.boundsPen import BoundsPen
    from fontTools.pens.svgPathPen import SVGPathPen
    from fontTools.pens.transformPen import TransformPen
    from fontTools.ttLib import TTFont
    from fontTools.varLib import instancer

    spec = WORDMARKS[direction]
    tt = TTFont(os.path.join(fonts_dir, spec["font"]))
    if "fvar" in tt:
        axes = {a.axisTag for a in tt["fvar"].axes}
        tt = instancer.instantiateVariableFont(tt, {k: v for k, v in spec["axes"].items() if k in axes})
    buf = io.BytesIO()
    tt.save(buf)
    font = hb.Font(hb.Face(buf.getvalue()))
    b = hb.Buffer()
    b.add_str(spec["text"])
    b.guess_segment_properties()
    hb.shape(font, b, {"kern": True, "liga": True})
    gs, order = tt.getGlyphSet(), tt.getGlyphOrder()
    upm = tt["head"].unitsPerEm
    k = 100.0 / upm
    pen, bp = SVGPathPen(gs), BoundsPen(gs)
    x = 0.0
    for info, pos in zip(b.glyph_infos, b.glyph_positions):
        g = gs[order[info.codepoint]]
        tr = (k, 0, 0, -k, (x + pos.x_offset) * k, -pos.y_offset * k)
        g.draw(TransformPen(pen, tr))
        g.draw(TransformPen(bp, tr))
        x += pos.x_advance + spec["tracking"] * upm
    minx, miny, maxx, maxy = bp.bounds
    return pen.getCommands(), [minx, miny, maxx - minx, maxy - miny]


# ------------------------------------------------------------------ palette helpers


def var(key):
    import re
    return "--color-" + re.sub(r"(?<!^)([A-Z])", r"-\1", key).lower()


def pal(direction, mode="light"):
    t = T.tokens(direction)
    i = 0 if mode == "light" else 1

    class P(dict):
        def __missing__(self, key):
            return t[var(key)][i]
    return P()


def gray(hexv):
    h = hexv.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) for i in (0, 2, 4))
    a = h[6:8] if len(h) == 8 else ""
    y = round(0.2126 * r + 0.7152 * g + 0.0722 * b)
    return "#%02X%02X%02X%s" % (y, y, y, a)


def layers_svg(layers, palette, mono=None):
    out = []
    for l in layers:
        c = palette[l["fill"]]
        if mono == "gray":
            c = gray(c)
        elif mono:
            c = mono
        op = l.get("opacity", 1)
        out.append(f'<path d="{l["geometry"]}" fill="{c}"' + (f' fill-opacity="{op}"' if op != 1 else "") + "/>")
    return "".join(out)


# ------------------------------------------------------------------ app icon

ICON = {
    "dayspring": dict(bg=("#F59A45", "#D4461A"), dark=("#173A35", "#0B1F1C"), face_scale=0.86, face_dy=40, sun="#FFD08A"),
    "flock": dict(bg=(T.tokens("flock")["--color-icon-top"][0], T.tokens("flock")["--color-icon-bottom"][0]),
                  dark=(T.tokens("flock")["--color-icon-top"][1], T.tokens("flock")["--color-icon-bottom"][1]),
                  face_scale=0.9, face_dy=46, sun=None),
    "still": dict(bg=("#3E80B5", "#1B4468"), dark=("#18344C", "#0A1620"), face_scale=0.8, face_dy=50, sun="#E9C46A",
                  scene=True),
}


def icon_svg(direction, appearance="default", size=1024):
    """appearance: default | dark | tinted (grayscale on black, for the system tint) | clear (white glyph)."""
    spec = ICON[direction]
    face = lambgen.face_front(direction, "Idle")
    p = pal(direction, "light")
    minx, miny, maxx, maxy = face["bounds"]
    fw, fh = maxx - minx, maxy - miny
    s = size * spec["face_scale"] / fw
    tx = size / 2 - (minx + fw / 2) * s
    ty = size / 2 - (miny + fh / 2) * s + spec["face_dy"]
    if appearance == "default":
        top, bot = spec["bg"]
    elif appearance == "dark":
        top, bot = spec["dark"]
    else:
        top = bot = "#000000"
    defs = (f'<defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{top}"/>'
            f'<stop offset="1" stop-color="{bot}"/></linearGradient>'
            f'<radialGradient id="sun" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="{spec["sun"] or top}" stop-opacity="0.9"/>'
            f'<stop offset="1" stop-color="{spec["sun"] or top}" stop-opacity="0"/></radialGradient></defs>')
    bg = f'<rect width="{size}" height="{size}" fill="url(#g)"/>'
    glow = ""
    if spec["sun"] and appearance in ("default", "dark"):
        r = size * 0.42
        glow = f'<circle cx="{size / 2}" cy="{size * 0.42}" r="{r}" fill="url(#sun)" opacity="{0.55 if appearance == "default" else 0.35}"/>'
    if spec.get("scene"):
        return scene_icon_svg(direction, appearance, size)
    if appearance == "tinted":
        tp = pal(direction, "light")
        if direction == "flock":
            tp = dict((k, tp[k]) for k in set(l["fill"] for l in face["layers"]))
            tp["mascotFace"] = "#6E6E6E"
        art = layers_svg(face["layers"], tp, mono="gray")
    elif appearance == "clear":
        art = f'<path d="{face["silhouette"]}" fill="#FFFFFF" fill-opacity="0.92"/>' + layers_svg(
            [l for l in face["layers"] if l["name"] in ("Eyes", "EyeWhites", "Nose", "Mouth", "Catchlights")], p,
            mono="#000000")
    else:
        art = layers_svg(face["layers"], p)
    g = f'<g transform="translate({tx:.2f},{ty:.2f}) scale({s:.4f})">{art}</g>'
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 {size} {size}">{defs}{bg}{glow}{g}</svg>'


def scene_icon_svg(direction, appearance="default", size=1024):
    """A lamb standing on a hill under a low gold sun: the silhouette is the icon."""
    spec = ICON[direction]
    data = lambgen.build_all(direction)
    st = data["stages"]["3"]
    vx, vy, vw, vh = st["viewBox"]
    layers = [l for l in st["expressions"]["Idle"] if l["name"] != "Shadow"]
    p = pal(direction, "light")
    top, bot = {"default": spec["bg"], "dark": spec["dark"]}.get(appearance, ("#000000", "#000000"))
    hill = {"default": "#2A6A5E", "dark": "#163A3A"}.get(appearance, "#3A3A3A")
    sun = spec["sun"] if appearance in ("default", "dark") else "#BDBDBD"
    k = size * 0.72 / vw
    tx, ty = size * 0.49 - (vx + vw / 2) * k, size * 0.775 - (vy + vh) * k
    if appearance == "tinted":
        art = layers_svg(layers, p, mono="gray")
    elif appearance == "clear":
        art = layers_svg(layers, p, mono="#FFFFFF")
        hill, sun = "#FFFFFF55", "#FFFFFFAA"
    else:
        art = layers_svg(layers, p)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 {size} {size}">'
            f'<defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{top}"/>'
            f'<stop offset="1" stop-color="{bot}"/></linearGradient></defs>'
            f'<rect width="{size}" height="{size}" fill="url(#g)"/>'
            f'<circle cx="{size * 0.76}" cy="{size * 0.2}" r="{size * 0.085}" fill="{sun}"/>'
            f'<ellipse cx="{size * 0.5}" cy="{size * 1.02}" rx="{size * 0.85}" ry="{size * 0.33}" fill="{hill}"/>'
            f'<g transform="translate({tx:.2f},{ty:.2f}) scale({k:.4f})">{art}</g></svg>')


def mark_svg(direction, size=100, chip=True, mode="light"):
    """The logo mark: the front face on an accent chip (or bare)."""
    face = lambgen.face_front(direction, "Idle")
    p = pal(direction, mode)
    minx, miny, maxx, maxy = face["bounds"]
    fw, fh = maxx - minx, maxy - miny
    k = (0.78 if chip else 0.98) * size / max(fw, fh)
    tx = size / 2 - (minx + fw / 2) * k
    ty = size / 2 - (miny + fh / 2) * k + (size * 0.04 if chip else 0)
    chip_svg = f'<circle cx="{size / 2}" cy="{size / 2}" r="{size / 2}" fill="{ICON[direction]["bg"][1]}"/>' if chip else ""
    return chip_svg + f'<g transform="translate({tx:.2f},{ty:.2f}) scale({k:.4f})">{layers_svg(face["layers"], p)}</g>'


def render(svg, path=None, scale=1.0):
    import resvg_py
    png = bytes(resvg_py.svg_to_bytes(svg_string=svg, zoom=scale) if scale != 1 else resvg_py.svg_to_bytes(svg_string=svg))
    if path:
        open(path, "wb").write(png)
    return png


def b64(png):
    return "data:image/png;base64," + base64.b64encode(png).decode()


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("direction")
    ap.add_argument("--fonts", required=True)
    ap.add_argument("--out", required=True)
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    for app in ("default", "dark", "tinted", "clear"):
        render(icon_svg(a.direction, app), os.path.join(a.out, f"icon_{app}.png"))
    d, bb = wordmark(a.direction, a.fonts)
    json.dump({"d": d, "bbox": bb, "licence": WORDMARKS[a.direction]["licence"]},
              open(os.path.join(a.out, "wordmark.json"), "w"))
    print("ok", a.direction, bb)
