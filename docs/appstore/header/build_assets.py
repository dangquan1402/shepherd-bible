"""Build Pasture's App Store product page header and search results creative assets.

Two variants each:
    header-a / header-b    3840 x 1646 (21:9 product page header)
    search-a / search-b    3840 x 2560 (3:2 search results, the maximum size)

Usage (needs pillow, resvg_py, uharfbuzz, fonttools; macOS for the New York and SF fonts):
    python3 -I docs/appstore/header/build_assets.py --out <dir> [--guides]

Everything is drawn from the repo: colours from tools/brand/tokens.py (direction "pasture", light),
the lamb from Shepherd/Resources/Content/lamb_variants.json (the app's own vector lamb), the meadow
shapes after MeadowBackgroundView/HillVignetteShape, and the phones are the committed goldie captures
in docs/appstore/screenshots/iphone-6.9 (real XCUITest screens in a real device frame).
Text is set in New York Bold (the app's .serif headings) and SF Pro, outlined with HarfBuzz.

Apple's "Art Safe Area" (measured from Apple's own creative asset templates, 2026-10-08):
    header 3840x1646: x 1097-2743, y 493-1154 (1646 x 661, centred)
    search 3840x2560: x 836-3004,  y 765-1795 (2168 x 1030, centred)
--guides draws those rectangles on an extra copy of each image for review.
"""

from __future__ import annotations

import argparse
import importlib.util
import io
import json
import math
from pathlib import Path

import resvg_py
from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[3]
LAMBS = ROOT / "Shepherd/Resources/Content/lamb_variants.json"
SHOTS = ROOT / "docs/appstore/screenshots/iphone-6.9"
NEW_YORK = "/System/Library/Fonts/NewYork.ttf"
SF_PRO = "/System/Library/Fonts/SFNS.ttf"

SAFE = {
    "header": (1097, 493, 2743, 1154),
    "search": (836, 765, 3004, 1795),
}
# Phone outline inside every goldie frame (1320 x 2868): outer edge of the device bezel.
PHONE_BOX = (130, 573, 1190, 2782)
PHONE_RADIUS = 188

# ------------------------------------------------------------------ palette


def _tokens():
    spec = importlib.util.spec_from_file_location("brand_tokens", ROOT / "tools/brand/tokens.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return {k: v[0] for k, v in mod.tokens("pasture").items()}


T = _tokens()


def c(name):
    return T[f"--color-{name}"]


def fill_key(key):
    """Lamb layer fills are camelCase token keys (mascotFleece -> --color-mascot-fleece)."""
    import re

    return T["--color-" + re.sub(r"(?<!^)([A-Z])", r"-\1", key).lower()]


def hexa(h):
    """#RRGGBB[AA] -> (fill, opacity) for SVG."""
    if len(h) == 9:
        return h[:7], int(h[7:], 16) / 255
    return h, 1.0


# ------------------------------------------------------------------ lamb


def lamb_svg(stage, expr, x, y, height, flip=False):
    """The app's lamb, feet-centre at (x, y), `height` px tall (viewBox height)."""
    st = json.loads(LAMBS.read_text())["stages"][str(stage)]
    vx, vy, vw, vh = st["viewBox"]
    s = height / vh
    out = []
    for layer in st["expressions"][expr]:
        col, op = hexa(fill_key(layer["fill"]))
        op *= layer.get("opacity", 1)
        if op <= 0:
            continue
        out.append(
            f'<path d="{layer["geometry"]}" fill="{col}"' + (f' fill-opacity="{op:.3f}"' if op < 1 else "") + "/>"
        )
    sx = -s if flip else s
    tx = x + (vw * s / 2 if flip else -vw * s / 2)
    return (
        f'<g transform="translate({tx:.1f},{y - height:.1f}) scale({sx:.4f},{s:.4f}) translate({-vx},{-vy})">'
        + "".join(out)
        + "</g>"
    )


def sparkle(cx, cy, r, col):
    """Four-point star like the Lesson Complete sparkles."""
    pts = []
    for i in range(8):
        a = math.radians(i * 45 - 90)
        rr = r if i % 2 == 0 else r * 0.32
        pts.append(f"{cx + rr * math.cos(a):.1f},{cy + rr * math.sin(a):.1f}")
    return f'<polygon points="{" ".join(pts)}" fill="{col}" stroke="{col}" stroke-width="{r * 0.08:.1f}" stroke-linejoin="round"/>'


# ------------------------------------------------------------------ meadow


def hill(W, H, y_left, c1, c2, y_right):
    """Hill silhouette like MeadowBackgroundView: one cubic across the width."""
    return f"M0,{H} L0,{y_left:.0f} C{c1[0]:.0f},{c1[1]:.0f} {c2[0]:.0f},{c2[1]:.0f} {W},{y_right:.0f} L{W},{H} Z"


def cloud(cx, cy, s, op=0.85):
    blobs = [(-1.0, 0.15, 0.55), (-0.35, -0.2, 0.75), (0.45, -0.05, 0.62), (1.05, 0.2, 0.45)]
    body = "".join(f'<circle cx="{cx + bx * s:.0f}" cy="{cy + by * s:.0f}" r="{br * s:.0f}"/>' for bx, by, br in blobs)
    base = f'<rect x="{cx - 1.45 * s:.0f}" y="{cy + 0.1 * s:.0f}" width="{2.9 * s:.0f}" height="{0.55 * s:.0f}" rx="{0.27 * s:.0f}"/>'
    return f'<g fill="#FFFFFF" fill-opacity="{op}">{body}{base}</g>'


def flower(x, y, r, col):
    petals = "".join(
        f'<circle cx="{x + r * math.cos(math.radians(a)):.1f}" cy="{y + r * math.sin(math.radians(a)):.1f}" r="{r * 0.62:.1f}"/>'
        for a in range(0, 360, 72)
    )
    return f'<g fill="{col}">{petals}</g><circle cx="{x}" cy="{y}" r="{r * 0.5:.1f}" fill="{c("gold-fill")}"/>'


def tuft(x, y, s, col):
    return (
        f'<path d="M{x - s},{y} Q{x - s * 0.6},{y - s * 1.2} {x - s * 0.15},{y - s * 1.9} '
        f"Q{x - s * 0.1},{y - s} {x},{y - s * 0.4} Q{x + s * 0.2},{y - s * 1.3} {x + s * 0.9},{y - s * 1.6} "
        f'Q{x + s * 0.55},{y - s * 0.8} {x + s},{y} Z" fill="{col}"/>'
    )


def hill_vignette(cx, base, w, h):
    """HillVignetteShape: the pedestal the lamb stands on in the app (320 x 70 design units)."""
    sx, sy = w / 320, h / 70
    x0, y0 = cx - w / 2, base - h

    def P(x, y):
        return f"{x0 + x * sx:.1f},{y0 + y * sy:.1f}"

    return (
        f'<linearGradient id="vig" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{c("meadow-hill-near")}"/>'
        f'<stop offset="1" stop-color="{c("meadow-hill-mid")}"/></linearGradient>'
        f'<path d="M{P(0, 70)} C{P(40, 20)} {P(110, 6)} {P(160, 6)} C{P(210, 6)} {P(280, 20)} {P(320, 70)} Z" fill="url(#vig)"/>'
    )


def defs(W, H, sun):
    sx, sy, sr = sun
    return f"""<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="{c("meadow-sky")}"/><stop offset="0.62" stop-color="{c("meadow-sky-bottom")}"/>
  </linearGradient>
  <radialGradient id="sun" cx="{sx}" cy="{sy}" r="{sr}" gradientUnits="userSpaceOnUse">
    <stop offset="0" stop-color="#FFFFFF" stop-opacity="0.95"/>
    <stop offset="0.35" stop-color="{c("gold-subtle")}" stop-opacity="0.75"/>
    <stop offset="1" stop-color="{c("gold-subtle")}" stop-opacity="0"/>
  </radialGradient>
  <linearGradient id="hillD" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#DCEDCB"/><stop offset="0.5" stop-color="{c("meadow-hill-distant")}"/>
  </linearGradient>
  <linearGradient id="hillM" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#C8E3B1"/><stop offset="0.6" stop-color="{c("meadow-hill-mid")}"/>
  </linearGradient>
  <linearGradient id="hillN" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#B2D99B"/><stop offset="0.5" stop-color="{c("meadow-hill-near")}"/>
    <stop offset="1" stop-color="#9DCB86"/>
  </linearGradient>
  <linearGradient id="path" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#FFF9E8"/><stop offset="1" stop-color="{c("meadow-path")}"/>
  </linearGradient>
  <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5">
    <stop offset="0" stop-color="{c("gold-fill")}" stop-opacity="0.55"/>
    <stop offset="1" stop-color="{c("gold-fill")}" stop-opacity="0"/>
  </radialGradient>
</defs>"""


def render_svg(svg, W, H):
    png = bytes(resvg_py.svg_to_bytes(svg_string=svg, width=W, height=H))
    return Image.open(io.BytesIO(png)).convert("RGBA")


# ------------------------------------------------------------------ text (outlined, kerned)

_FONTS = {}


def _font(path, axes):
    import uharfbuzz as hb
    from fontTools.ttLib import TTFont
    from fontTools.varLib import instancer

    key = (path, tuple(sorted(axes.items())))
    if key not in _FONTS:
        tt = TTFont(path)
        tt = instancer.instantiateVariableFont(tt, axes)
        buf = io.BytesIO()
        tt.save(buf)
        _FONTS[key] = (tt, hb.Font(hb.Face(buf.getvalue())))
    return _FONTS[key]


def text_path(text, path, axes, size, tracking=0.0):
    """Return (svg path d at origin baseline, advance width, (minx, miny, maxx, maxy))."""
    import uharfbuzz as hb
    from fontTools.pens.boundsPen import BoundsPen
    from fontTools.pens.svgPathPen import SVGPathPen
    from fontTools.pens.transformPen import TransformPen

    tt, font = _font(path, axes)
    b = hb.Buffer()
    b.add_str(text)
    b.guess_segment_properties()
    hb.shape(font, b, {"kern": True, "liga": True})
    gs, order = tt.getGlyphSet(), tt.getGlyphOrder()
    upm = tt["head"].unitsPerEm
    k = size / upm
    pen, bp = SVGPathPen(gs), BoundsPen(gs)
    x = 0.0
    for info, pos in zip(b.glyph_infos, b.glyph_positions):
        g = gs[order[info.codepoint]]
        tr = (k, 0, 0, -k, (x + pos.x_offset) * k, -pos.y_offset * k)
        g.draw(TransformPen(pen, tr))
        g.draw(TransformPen(bp, tr))
        x += pos.x_advance + tracking * upm
    return pen.getCommands(), x * k, bp.bounds


SERIF_BOLD = (NEW_YORK, {"wght": 700, "opsz": 96, "GRAD": 0})
SANS_MED = (SF_PRO, {"wght": 510, "opsz": 28, "wdth": 100, "GRAD": 400})


def text_runs(runs, x, baseline, size, font=SERIF_BOLD, align="left", tracking=-0.012):
    """runs: [(text, colour)]; returns (svg, width)."""
    pieces, cursor = [], 0.0
    space = text_path(" ", font[0], font[1], size, tracking)[1]
    for i, (t, col) in enumerate(runs):
        d, adv, _ = text_path(t, font[0], font[1], size, tracking)
        pieces.append((d, col, cursor))
        cursor += adv + (space if i < len(runs) - 1 else 0)
    width = cursor
    x0 = x - width / 2 if align == "center" else x
    svg = "".join(
        f'<path transform="translate({x0 + off:.1f},{baseline:.1f})" d="{d}" fill="{col}"/>' for d, col, off in pieces
    )
    return svg, width


# ------------------------------------------------------------------ phones


def phone(name, height):
    """Cut the real device + screen out of a committed goldie capture, scaled to `height` px."""
    im = Image.open(SHOTS / name).convert("RGBA")
    x0, y0, x1, y1 = PHONE_BOX
    crop = im.crop(PHONE_BOX)
    ss = 4
    mask = Image.new("L", ((x1 - x0) * ss, (y1 - y0) * ss), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (ss, ss, (x1 - x0) * ss - ss, (y1 - y0) * ss - ss), radius=PHONE_RADIUS * ss, fill=255
    )
    mask = mask.resize(crop.size, Image.LANCZOS)
    crop.putalpha(mask)
    w = round(crop.width * height / crop.height)
    return crop.resize((w, height), Image.LANCZOS)


def drop_shadow(canvas, img, x, y, blur, offset, opacity):
    a = img.split()[3].point(lambda v: v * opacity)
    sh = Image.new("RGBA", img.size, c("text-primary"))
    sh.putalpha(a)
    pad = blur * 3
    layer = Image.new("RGBA", (img.width + pad * 2, img.height + pad * 2), (0, 0, 0, 0))
    layer.paste(sh, (pad, pad), sh)
    layer = layer.filter(ImageFilter.GaussianBlur(blur))
    _paste_any(canvas, layer, x - pad, y - pad + offset)


def _paste_any(canvas, layer, x, y):
    """alpha_composite that tolerates negative / overflowing offsets."""
    tmp = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    tmp.paste(layer, (x, y))  # straight copy: a mask here would square the alpha
    canvas.alpha_composite(tmp)


def place(canvas, img, x, y, shadow=True):
    if shadow:
        drop_shadow(canvas, img, x, y, blur=46, offset=34, opacity=0.22)
    _paste_any(canvas, img, x, y)


# ------------------------------------------------------------------ scenes


class Ground:
    """A road on a ground plane seen in perspective: depth z >= 1, y = yh + D / z.

    The road keeps a constant ground width, so its edges never cross however it winds.
    """

    def __init__(self, cx, yh, D, width, amp, freq, phase):
        self.cx, self.yh, self.D, self.w = cx, yh, D, width
        self.amp, self.freq, self.phase = amp, freq, phase

    def lateral(self, z):  # ground offset; amp is the on-screen swing in px
        return self.amp * z * math.sin(self.freq * z + self.phase)

    def screen(self, z, dx=0.0):
        return self.cx + (self.lateral(z) + dx) / z, self.yh + self.D / z

    def z_at(self, y):
        return self.D / (y - self.yh)

    def x_at(self, y):
        return self.screen(self.z_at(y))[0]

    def scale_at(self, y):
        return 1 / self.z_at(y)

    def band(self, half, z0=0.9, z1=40, n=400):
        zs = [z0 * (z1 / z0) ** (i / n) for i in range(n + 1)]
        left = [self.screen(z, -half) for z in zs]
        right = [self.screen(z, half) for z in zs]
        pts = left + right[::-1]
        return "M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in pts) + " Z"


def meadow_header(W, H):
    """Wide meadow: sky, sun glow, three hills, a road winding from the viewer over the crest."""
    sun = (W * 0.5, H * 0.34, H * 0.95)
    s = [defs(W, H, sun), f'<rect width="{W}" height="{H}" fill="url(#sky)"/>']
    s.append(f'<rect width="{W}" height="{H}" fill="url(#sun)"/>')
    s += [cloud(W * 0.12, H * 0.2, 150, 0.95), cloud(W * 0.87, H * 0.15, 120, 0.9), cloud(W * 0.73, H * 0.31, 64, 0.7)]
    s.append(
        f'<path d="{hill(W, H, H * 0.53, (W * 0.28, H * 0.43), (W * 0.64, H * 0.66), H * 0.47)}" fill="url(#hillD)"/>'
    )
    mid = hill(W, H, H * 0.69, (W * 0.36, H * 0.57), (W * 0.66, H * 0.6), H * 0.66)
    s.append(f'<clipPath id="crest"><path d="{mid}"/></clipPath>')
    s.append(f'<path d="{mid}" fill="url(#hillM)"/>')
    s.append(
        f'<path d="{hill(W, H, H * 0.84, (W * 0.3, H * 0.76), (W * 0.7, H * 0.86), H * 0.8)}" fill="url(#hillN)"/>'
    )
    g = Ground(cx=W * 0.5, yh=H * 0.5, D=H * 0.56, width=1150, amp=230, freq=1.15, phase=-3.39)
    s.append(f'<g clip-path="url(#crest)"><path d="{g.band(g.w / 2 + 36)}" fill="{c("meadow-path-border")}"/>')
    s.append(f'<path d="{g.band(g.w / 2)}" fill="url(#path)"/></g>')
    for fx, fy, fr, col in [
        (0.06, 0.94, 18, "#FFFFFF"),
        (0.13, 0.87, 13, c("mascot-flower")),
        (0.22, 0.96, 15, "#FFFFFF"),
        (0.29, 0.9, 11, "#FFFFFF"),
        (0.7, 0.93, 14, c("mascot-flower")),
        (0.79, 0.97, 18, "#FFFFFF"),
        (0.9, 0.86, 13, "#FFFFFF"),
        (0.96, 0.95, 12, c("mascot-flower")),
        (0.62, 0.74, 9, "#FFFFFF"),
        (0.37, 0.72, 9, c("mascot-flower")),
        (0.41, 0.79, 8, "#FFFFFF"),
        (0.66, 0.68, 7, "#FFFFFF"),
    ]:
        s.append(flower(W * fx, H * fy, fr, col))
    for tx, ty, ts in [
        (0.04, 0.99, 36),
        (0.18, 0.92, 26),
        (0.75, 0.99, 32),
        (0.93, 0.92, 28),
        (0.34, 0.78, 16),
        (0.64, 0.72, 14),
    ]:
        s.append(tuft(W * tx, H * ty, ts, "#86BC70"))
    return s, g


def node(cx, cy, r, state):
    """Lesson node like the Today path: current = evergreen disc with white ring and sunflower glow."""
    if state == "current":
        return (
            f'<circle cx="{cx}" cy="{cy}" r="{r * 1.9:.0f}" fill="url(#glow)"/>'
            f'<circle cx="{cx}" cy="{cy}" r="{r * 1.12:.0f}" fill="{c("node-current-ring")}"/>'
            f'<circle cx="{cx}" cy="{cy}" r="{r:.0f}" fill="{c("accent-fill")}"/>' + book(cx, cy, r * 0.5, "#FFFFFF")
        )
    return (
        f'<circle cx="{cx}" cy="{cy + r * 0.12:.0f}" r="{r:.0f}" fill="{c("node-locked-deep")}"/>'
        f'<circle cx="{cx}" cy="{cy}" r="{r:.0f}" fill="{c("node-locked")}"/>'
    )


def book(cx, cy, s, col):
    """Open book glyph (two pages), the Today node's symbol."""
    return (
        f'<path d="M{cx - s * 0.06},{cy - s * 0.55} Q{cx - s * 0.5},{cy - s * 0.8} {cx - s},{cy - s * 0.6} L{cx - s},{cy + s * 0.7} '
        f'Q{cx - s * 0.5},{cy + s * 0.5} {cx - s * 0.06},{cy + s * 0.75} Z" fill="{col}"/>'
        f'<path d="M{cx + s * 0.06},{cy - s * 0.55} Q{cx + s * 0.5},{cy - s * 0.8} {cx + s},{cy - s * 0.6} L{cx + s},{cy + s * 0.7} '
        f'Q{cx + s * 0.5},{cy + s * 0.5} {cx + s * 0.06},{cy + s * 0.75} Z" fill="{col}"/>'
    )


def svg_doc(parts, W, H):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}">' + "".join(parts) + "</svg>"


def header_a(W=3840, H=1646):
    """Pure brand: the lamb standing on the meadow path, no text, no UI."""
    s, _ = meadow_header(W, H)
    feet = 1135
    s.append(lamb_svg(3, "Happy", W * 0.5 + 60, feet, 560))
    s.append(sparkle(W * 0.5 - 420, 690, 50, c("gold-fill")))
    s.append(sparkle(W * 0.5 + 370, 610, 36, c("gold-fill")))
    s.append(sparkle(W * 0.5 - 330, 560, 24, c("gold-fill")))
    return render_svg(svg_doc(s, W, H), W, H)


def header_b(W=3840, H=1646):
    """A hint of the app: the Today path's lesson nodes on the meadow, the lamb beside today's lesson."""
    s, g = meadow_header(W, H)
    y = 1150
    r = 320 * g.scale_at(y)
    s.append(node(g.x_at(y) - 60, y - r * 1.05, r, "current"))
    s.append(lamb_svg(3, "Happy", W * 0.5 + 420, 1140, 470))
    s.append(sparkle(W * 0.5 + 700, 690, 40, c("gold-fill")))
    s.append(sparkle(W * 0.5 - 330, 760, 30, c("gold-fill")))
    return render_svg(svg_doc(s, W, H), W, H)


def search_bg(W, H, horizon):
    sun = (W * 0.5, H * 0.3, H * 0.8)
    s = [
        defs(W, H, sun),
        f'<rect width="{W}" height="{H}" fill="url(#sky)"/>',
        f'<rect width="{W}" height="{H}" fill="url(#sun)"/>',
    ]
    s += [cloud(W * 0.1, H * 0.16, 140, 0.9), cloud(W * 0.9, H * 0.12, 120, 0.85)]
    s.append(
        f'<path d="{hill(W, H, horizon, (W * 0.3, horizon - 120), (W * 0.62, horizon + 120), horizon - 60)}" fill="url(#hillD)"/>'
    )
    s.append(
        f'<path d="{hill(W, H, horizon + 260, (W * 0.38, horizon + 140), (W * 0.7, horizon + 330), horizon + 180)}" fill="url(#hillM)"/>'
    )
    s.append(
        f'<path d="{hill(W, H, horizon + 560, (W * 0.3, horizon + 430), (W * 0.72, horizon + 620), horizon + 470)}" fill="url(#hillN)"/>'
    )
    for fx, fy, fr, col in [
        (0.06, 0.93, 18, "#FFFFFF"),
        (0.13, 0.97, 14, c("mascot-flower")),
        (0.87, 0.95, 16, "#FFFFFF"),
        (0.94, 0.9, 13, c("mascot-flower")),
    ]:
        s.append(flower(W * fx, H * fy, fr, col))
    return s


def headline_svg(cx, baseline, size, align="center", x=None):
    ink, brand = c("text-primary"), c("accent")
    return text_runs(
        [("A little Bible,", ink), ("every day", brand)], x if x is not None else cx, baseline, size, align=align
    )


def search_a(W=3840, H=2560):
    """Centred: headline in the safe area, three real screens fanned below, the lamb on the hill."""
    s = search_bg(W, H, horizon=1500)
    head, hw = headline_svg(W / 2, 985, 184)
    s.append(head)
    s.append(hill_vignette(3390, 2330, 760, 160))
    s.append(lamb_svg(3, "Happy", 3390, 2210, 400))
    s.append(sparkle(3130, 1790, 40, c("gold-fill")))
    s.append(sparkle(3640, 1740, 30, c("gold-fill")))
    canvas = render_svg(
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}">' + "".join(s) + "</svg>", W, H
    )
    side_h, mid_h = 1440, 1620
    left, right, mid = phone("02-lesson.png", side_h), phone("03-quiz.png", side_h), phone("01-today.png", mid_h)
    overlap = 110
    mx = (W - mid.width) // 2
    place(canvas, left, mx - left.width + overlap, 1300)
    place(canvas, right, mx + mid.width - overlap, 1300)
    place(canvas, mid, mx, 1120)
    return canvas, hw


def search_b(W=3840, H=2560):
    """Split: lamb + two-line headline + subline on the left, two real screens on the right."""
    s = search_bg(W, H, horizon=1560)
    x = 900
    l1, w1 = text_runs([("A little Bible,", c("text-primary"))], x, 1262, 198)
    l2, w2 = text_runs([("every day", c("accent"))], x, 1484, 198)
    sub, ws = text_runs(
        [("Short guided lessons on a path", c("text-secondary"))], x + 8, 1636, 82, font=SANS_MED, tracking=0
    )
    sub2, _ = text_runs([("you can follow", c("text-secondary"))], x + 8, 1744, 82, font=SANS_MED, tracking=0)
    s += [l1, l2, sub, sub2]
    s.append(hill_vignette(x + 270, 1070, 600, 128))
    s.append(lamb_svg(3, "Happy", x + 270, 1006, 268))
    s.append(sparkle(x + 560, 830, 38, c("gold-fill")))
    canvas = render_svg(
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}">' + "".join(s) + "</svg>", W, H
    )
    back, front = phone("02-lesson.png", 1640), phone("01-today.png", 1800)
    place(canvas, back, 2860, 760)
    place(canvas, front, 2260, 640)
    return canvas, max(w1, w2, ws)


# ------------------------------------------------------------------ output


def flatten(img):
    """sRGB, no alpha: composite on the canvas colour and drop the channel."""
    bg = Image.new("RGB", img.size, c("canvas-bg"))
    bg.paste(img, mask=img.split()[3])
    return ImageChops.add(bg, dither(img.size), scale=1.0, offset=-128)


def dither(size):
    """+-1 level of seeded luminance noise (tiled) to break up 8-bit banding in the wide sky gradients."""
    import random

    rnd = random.Random(7)
    tile = Image.frombytes("L", (256, 256), bytes(127 + rnd.choice((0, 1, 1, 2)) for _ in range(256 * 256)))
    out = Image.new("L", size)
    for y in range(0, size[1], 256):
        for x in range(0, size[0], 256):
            out.paste(tile, (x, y))
    return out.convert("RGB")


# macOS's own sRGB profile (byte-stable, unlike a generated one that carries a timestamp)
SRGB = Path("/System/Library/ColorSync/Profiles/sRGB Profile.icc").read_bytes()


def guides(img, kind):
    g = img.copy().convert("RGB")
    d = ImageDraw.Draw(g)
    x0, y0, x1, y1 = SAFE[kind]
    for i in range(6):
        d.rectangle((x0 - i, y0 - i, x1 + i, y1 + i), outline=(255, 0, 170))
    return g


FINAL = {"header": "header-a", "search": "search-b"}


def preview(out):
    """Contact sheet: finals at 25%, both variants, 10% thumbnails and the safe-area crop of each."""
    from PIL import ImageFont

    font = ImageFont.truetype(SF_PRO, 30)
    small = ImageFont.truetype(SF_PRO, 24)
    rows = []
    for name in ("header-a", "header-b", "search-a", "search-b"):
        kind = name.split("-")[0]
        im = Image.open(out / f"{name}.png").convert("RGB")
        q = im.resize((im.width // 4, im.height // 4), Image.LANCZOS)
        t = im.resize((im.width // 10, im.height // 10), Image.LANCZOS)
        x0, y0, x1, y1 = SAFE[kind]
        sc = im.crop(SAFE[kind])
        sc = sc.resize((sc.width // 4, sc.height // 4), Image.LANCZOS)
        g = ImageDraw.Draw(q)
        g.rectangle((x0 // 4, y0 // 4, x1 // 4, y1 // 4), outline=(255, 0, 170), width=2)
        h = q.height + 70
        row = Image.new("RGB", (q.width + t.width + sc.width + 80, h), c("canvas-bg"))
        d = ImageDraw.Draw(row)
        chosen = FINAL[kind] == name
        label = f"{name}  {im.width}x{im.height}" + ("   CHOSEN" if chosen else "   alternate")
        d.text((20, 14), label, font=font, fill=c("accent") if chosen else c("text-secondary"))
        row.paste(q, (20, 60))
        row.paste(t, (q.width + 40, 60))
        d.text((q.width + 40, 60 + t.height + 8), "10%", font=small, fill=c("text-tertiary"))
        row.paste(sc, (q.width + t.width + 60, 60))
        d.text(
            (q.width + t.width + 60, 60 + sc.height + 8),
            "Apple art safe area only",
            font=small,
            fill=c("text-tertiary"),
        )
        rows.append(row)
    W = max(r.width for r in rows)
    sheet = Image.new("RGB", (W, sum(r.height for r in rows) + 20 * len(rows)), c("canvas-bg"))
    y = 0
    for r in rows:
        sheet.paste(r, (0, y))
        y += r.height + 20
    sheet.save(out / "preview.png", optimize=True, icc_profile=SRGB)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--guides", action="store_true")
    a = ap.parse_args()
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    jobs = {
        "header-a": ("header", header_a),
        "header-b": ("header", header_b),
        "search-a": ("search", lambda: search_a()[0]),
        "search-b": ("search", lambda: search_b()[0]),
    }
    for name, (kind, fn) in jobs.items():
        img = flatten(fn())
        img.save(out / f"{name}.png", optimize=True, icc_profile=SRGB)
        if a.guides:
            guides(img, kind).save(out / f"{name}-guides.png")
        print(f"{name}: {img.size[0]}x{img.size[1]} {img.mode}")
    preview(out)
    print("preview.png (25% with the safe area outlined, 10% thumbnail, safe-area crop)")


if __name__ == "__main__":
    main()
