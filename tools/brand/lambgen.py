"""Parametric generator for the Shepherd lamb.

Builds every lamb variant (5 stages x 6 expressions), the 56 pt avatars and the
24 pt tab glyph as filled polyline paths ("M x y l dx dy ... z"), the format
LambView's SVGPathParser reads. Fills are colour-token keys, resolved by the app
(ShepherdTheme) or by a palette dict when rendering SVG previews.

Usage (needs shapely):
    python3 tools/brand/lambgen.py --style flock --out Shepherd/Resources/Content/lamb_variants.json
"""
from __future__ import annotations

import argparse
import json
import math
from dataclasses import dataclass, field

from shapely import affinity
from shapely.geometry import LineString, MultiPolygon, Point, Polygon, box
from shapely.geometry.polygon import orient
from shapely.ops import unary_union

RES = 20
EXPRESSIONS = ["Idle", "Happy", "Encouraging", "Celebrating", "Sleepy", "Hello"]
STAGE_NAMES = {1: "Newborn", 2: "Lamb", 3: "Young sheep", 4: "Yearling", 5: "Grown sheep"}

# ---------------------------------------------------------------- primitives


def circ(cx, cy, r):
    return Point(cx, cy).buffer(r, resolution=RES)


def ell(cx, cy, rx, ry, rot=0.0):
    g = affinity.scale(Point(0, 0).buffer(1, resolution=RES), rx, ry, origin=(0, 0))
    if rot:
        g = affinity.rotate(g, rot, origin=(0, 0))
    return affinity.translate(g, cx, cy)


def stroke(pts, w):
    return LineString(pts).buffer(w / 2, resolution=RES, cap_style=1, join_style=1)


def arc_pts(cx, cy, rx, ry, a0, a1, n=20):
    return [
        (cx + rx * math.cos(math.radians(a0 + (a1 - a0) * i / n)),
         cy + ry * math.sin(math.radians(a0 + (a1 - a0) * i / n)))
        for i in range(n + 1)
    ]


def quad_pts(p0, p1, p2, n=20):
    out = []
    for i in range(n + 1):
        t = i / n
        out.append(((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0],
                    (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]))
    return out


def hull2(a, b):
    return unary_union([a, b]).convex_hull


def leaf(x, y, length, width, angle_deg, tip=0.42):
    """Teardrop from a round root at (x, y) towards angle (y-down degrees)."""
    a = math.radians(angle_deg)
    root = circ(x + math.cos(a) * width * 0.5, y + math.sin(a) * width * 0.5, width * 0.5)
    tx = x + math.cos(a) * (length - width * tip * 0.5)
    ty = y + math.sin(a) * (length - width * tip * 0.5)
    return hull2(root, circ(tx, ty, width * tip * 0.5))


def star4(cx, cy, R, r=None, rot=0):
    r = r or R * 0.34
    pts = []
    for i in range(8):
        a = math.radians(rot - 90 + i * 45)
        rr = R if i % 2 == 0 else r
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    return Polygon(pts).buffer(R * 0.06, resolution=RES)


def smooth(g, r):
    return g.buffer(r, resolution=RES).buffer(-r, resolution=RES)


def rot(g, deg, about):
    return affinity.rotate(g, deg, origin=about)


def move(g, dx, dy):
    return affinity.translate(g, dx, dy)


# ---------------------------------------------------------------- styles


@dataclass
class Style:
    key: str
    head_scale: float = 1.0          # head radius multiplier
    body: str = "lobes"              # lobes | bun | pebble
    lobes: int = 5
    tuft: str = "three"              # three | cap | soft | none
    tuft_s1: bool = False
    eyes: str = "dot"                # dot | white | bead
    eye_scale: float = 1.0
    outline: float = 0.0             # 0 = none; else rim width in units
    curls: bool = False
    cheeks: bool = True
    leg_w: float = 7.0
    ear_len: float = 1.15
    ear_w: float = 0.5
    ear_tip: float = 0.78
    mouth_key: str = "mascotFeatures"
    nose_key: str = "mascotFeatures"
    leg_key: str = "mascotLegs"
    sparkle_key: str = "accentFill"
    collar: str = "ribbon"           # ribbon | bandana
    extras: dict = field(default_factory=dict)


STYLES = {
    # A: the current warm lamb, refined: tone rim, five soft lobes, cream face
    "dayspring": Style("dayspring", head_scale=1.05, body="lobes", lobes=5, tuft="three",
                       ear_len=1.0, eyes="dot", eye_scale=1.12, outline=1.5, cheeks=True, leg_w=6.6),
    # B: a black-faced lamb with big bright eyes and a fleece cap
    "flock": Style("flock", head_scale=1.16, body="bun", tuft="cap", tuft_s1=True, eyes="white",
                   eye_scale=1.0, outline=0.0, curls=True, cheeks=True, leg_w=7.4,
                   ear_len=1.0, ear_w=0.5, ear_tip=0.7, mouth_key="mascotEyeWhite", nose_key="mascotBlush", sparkle_key="goldFill", collar="bandana"),
    # C: a quiet pebble lamb: one smooth shape, bead eyes, no blush
    "still": Style("still", head_scale=1.0, body="pebble", tuft="soft", tuft_s1=True, eyes="bead",
                   eye_scale=1.25, outline=0.0, cheeks=True, leg_w=5.4, ear_len=0.98, ear_w=0.46, ear_tip=0.86,
                   sparkle_key="goldFill"),
}

# Stage geometry in a ~120-unit box; the lamb faces three-quarters left.
STAGES = {
    1: dict(pose="lying", bx=64, by=76, rx=35, ry=19, hx=31, hy=62, hr=19.5, ground=95),
    2: dict(pose="sitting", bx=66, by=66, rx=26, ry=24, hx=43, hy=40, hr=18.5, ground=92),
    3: dict(pose="standing", bx=67, by=57, rx=32, ry=21, hx=33, hy=40, hr=17.5, ground=93, legs=(66, 92)),
    4: dict(pose="standing", bx=69, by=55, rx=36, ry=23, hx=33, hy=36, hr=18, ground=97, legs=(66, 96)),
    5: dict(pose="standing", bx=71, by=55, rx=40, ry=25.5, hx=33, hy=34, hr=18.5, ground=99, legs=(68, 98)),
}


# ---------------------------------------------------------------- builder


class Lamb:
    def __init__(self, style: Style, stage: int, expr: str):
        self.s = style
        self.stage = stage
        self.expr = expr
        p = dict(STAGES[stage])
        if expr == "Sleepy" and p["pose"] != "lying":
            # every stage sleeps lying down, sized to its stage
            k = p["rx"] / 32.0
            p.update(pose="lying", by=p["ground"] - 18 * k, ry=18 * k + 1.5, rx=p["rx"] + 2,
                     hx=p["bx"] - p["rx"] - 1, hy=p["ground"] - 32 * k)
        p["hr"] *= style.head_scale
        if stage == 1:
            p["hr"] *= 1.04
        self.p = p
        self.layers: list[tuple[str, str, object, float]] = []

    # geometry helpers bound to this lamb
    def add(self, name, key, geom, opacity=1.0):
        if geom is None or geom.is_empty:
            return
        self.layers.append((name, key, geom, opacity))

    def build(self):
        s, p, e = self.s, self.p, self.expr
        hx, hy, hr = p["hx"], p["hy"], p["hr"]
        bx, by, rx, ry = p["bx"], p["by"], p["rx"], p["ry"]
        lift = 0.0
        if e == "Happy":
            lift = -3.0
        if e == "Celebrating" and p["pose"] == "lying":
            lift = -7.0
        elif e == "Celebrating":
            lift = -2.0

        # ---- body
        if s.body == "lobes":
            base = ell(bx, by, rx - ry * 0.25, ry * 0.92)
            parts = [base]
            n = s.lobes
            for i in range(n):
                a = 200 + (340 - 200) * i / (n - 1)
                cx = bx + (rx - ry * 0.48) * math.cos(math.radians(a))
                cy = by + (ry * 0.58) * math.sin(math.radians(a))
                parts.append(circ(cx, cy, ry * 0.5))
            # rump and belly lobes keep the silhouette woolly all round
            parts.append(circ(bx + rx - ry * 0.55, by + ry * 0.15, ry * 0.55))
            parts.append(circ(bx - rx * 0.35, by + ry * 0.38, ry * 0.5))
            parts.append(circ(bx + rx * 0.2, by + ry * 0.42, ry * 0.5))
            fleece = smooth(unary_union(parts), 1.6)
            tail = circ(bx + rx * 0.98, by - ry * 0.18, ry * 0.26)
        elif s.body == "bun":
            cr = ry * 0.82
            core = box(bx - rx + cr, by - ry + cr, bx + rx - cr, by + ry - cr).buffer(cr, resolution=RES)
            bumps = [circ(bx - rx * 0.3, by - ry * 0.78, ry * 0.42), circ(bx + rx * 0.12, by - ry * 0.86, ry * 0.44),
                     circ(bx + rx * 0.52, by - ry * 0.7, ry * 0.4)]
            fleece = smooth(unary_union([core] + bumps), 2.2)
            tail = circ(bx + rx * 0.97, by - ry * 0.3, ry * 0.3)
        else:  # pebble
            fleece = ell(bx, by, rx, ry * 0.96)
            fleece = unary_union([fleece, ell(bx + rx * 0.1, by - ry * 0.62, rx * 0.72, ry * 0.5)])
            fleece = smooth(fleece, 3)
            tail = circ(bx + rx * 0.98, by - ry * 0.32, ry * 0.2)
        fleece = unary_union([fleece, tail])
        fleece = move(fleece, 0, lift)

        # ---- legs
        far_legs, near_legs, hooves = [], [], []
        lw = s.leg_w * (0.9 if self.stage <= 2 else 1.0)
        if p["pose"] == "standing":
            top, bot = p["legs"]
            top += lift
            xs_near = [bx - rx * 0.5, bx + rx * 0.5]
            xs_far = [x + lw * 1.05 for x in xs_near]
            for i, x in enumerate(xs_far):
                g = stroke([(x, top), (x, bot - 1.2)], lw)
                if e == "Celebrating" and i == 0:
                    g = rot(g, 28, (x, top))
                far_legs.append(g)
            for i, x in enumerate(xs_near):
                g = stroke([(x, top), (x, bot)], lw)
                if e == "Celebrating" and i == 0:
                    g = rot(g, 32, (x, top))
                if e == "Hello" and i == 0:
                    g = None
                if g is not None:
                    near_legs.append(g)
        elif p["pose"] == "sitting":
            ground = p["ground"]
            x0 = hx + hr * 0.25
            for k, x in enumerate([x0 + lw * 1.1, x0]):
                g = stroke([(x, by - 4 + lift), (x, ground - (1.2 if k == 0 else 0))], lw)
                if e == "Celebrating":
                    g = rot(g, 30, (x, by - 4 + lift))
                if e == "Hello" and k == 1:
                    g = None
                if g is not None:
                    (far_legs if k == 0 else near_legs).append(g)
            # folded hind leg peeks out at the back
            far_legs.append(stroke([(bx + rx * 0.35, ground - lw * 0.5), (bx + rx * 0.85, ground - lw * 0.5)], lw))
        else:  # lying: tucked hooves under the chest
            ground = p["ground"]
            y = ground - lw * 0.5 + lift
            near_legs.append(stroke([(bx - rx * 0.5, y), (bx - rx * 0.3, y)], lw))
            far_legs.append(stroke([(bx - rx * 0.22, y - 0.6), (bx - rx * 0.02, y - 0.6)], lw))
        for g in near_legs + far_legs:
            minx, miny, maxx, maxy = g.bounds
            hooves.append(g.intersection(box(minx - 1, maxy - lw * 0.75, maxx + 1, maxy + 1)))
        if p["pose"] == "lying":
            hooves = []

        # ---- head group (rotates for Encouraging)
        hy_l = hy + lift
        head = hull2(circ(hx, hy_l, hr), circ(hx - hr * 0.1, hy_l + hr * 0.5, hr * 0.66))
        ear_near_a, ear_far_a = {"Idle": (164, 16), "Happy": (182, 0), "Encouraging": (172, -10),
                                 "Celebrating": (186, -6), "Sleepy": (140, 42), "Hello": (190, -8)}[e]
        if self.stage == 1:
            ear_near_a -= 10 if e not in ("Happy", "Celebrating", "Hello") else 0
            ear_far_a += 10 if e not in ("Happy", "Celebrating", "Hello") else 0
        el, ew = hr * s.ear_len, hr * s.ear_w
        ear_near = leaf(hx - hr * 0.78, hy_l - hr * 0.1, el, ew, ear_near_a, s.ear_tip)
        ear_far = leaf(hx + hr * 0.62, hy_l - hr * 0.28, el * 0.92, ew * 0.94, ear_far_a, s.ear_tip)

        def inner(ear_root, a, L, W):
            return leaf(ear_root[0] + math.cos(math.radians(a)) * W * 0.35,
                        ear_root[1] + math.sin(math.radians(a)) * W * 0.4, L * 0.55, W * 0.46, a, s.ear_tip)

        ear_near_in = inner((hx - hr * 0.78, hy_l - hr * 0.1), ear_near_a, el, ew)
        ear_far_in = inner((hx + hr * 0.62, hy_l - hr * 0.28), ear_far_a, el * 0.92, ew * 0.94)

        tuft = None
        if s.tuft != "none" and (self.stage > 1 or s.tuft_s1):
            if s.tuft == "three":
                n = 3 if self.stage >= 3 else 2
                xs = [hx - hr * 0.3 + i * hr * 0.3 for i in range(n)]
                tuft = unary_union([circ(x, hy_l - hr * 0.86, hr * 0.27) for x in xs])
            elif s.tuft == "cap":
                k = 0.92 if self.stage == 1 else 1.0
                pts = [(-0.52, -0.6, 0.34), (-0.18, -0.86, 0.38), (0.2, -0.86, 0.37), (0.52, -0.6, 0.32),
                       (0.0, -0.62, 0.42)]
                if self.stage >= 3:
                    pts.append((-0.02, -1.08, 0.3))
                tuft = unary_union([circ(hx + dx * hr, hy_l + dy * hr, r * hr * k) for dx, dy, r in pts])
                tuft = smooth(tuft, 1.2)
            else:  # soft
                tuft = ell(hx + hr * 0.02, hy_l - hr * 0.84, hr * 0.42, hr * 0.26, -8)

        # ---- face
        eye_y = hy_l + hr * 0.14
        ex = [hx - hr * 0.44, hx + hr * 0.24]
        nose_c = (hx - hr * 0.12, hy_l + hr * 0.5)
        if s.eyes == "white":
            eye_y = hy_l + hr * 0.08
            ex = [hx - hr * 0.42, hx + hr * 0.2]
            nose_c = (hx - hr * 0.13, hy_l + hr * 0.56)
        big = 1.14 if self.stage == 1 else 1.0
        er = hr * s.eye_scale * big
        eyes, whites, catch = [], [], []
        ew_key = "mascotEyeWhite"
        closed_line_key = "mascotFeatures" if s.eyes != "white" else ew_key
        look = (-0.05, 0.0) if e != "Encouraging" else (-0.07, -0.07)
        if e in ("Idle", "Encouraging", "Hello"):
            for x in ex:
                if s.eyes == "dot":
                    eyes.append(ell(x, eye_y, er * 0.13, er * 0.165))
                    catch.append(circ(x + er * 0.045, eye_y - er * 0.065, er * 0.05))
                elif s.eyes == "white":
                    whites.append(ell(x, eye_y, er * 0.2, er * 0.235))
                    px, py = x + look[0] * er, eye_y + look[1] * er + er * 0.02
                    eyes.append(ell(px, py, er * 0.125, er * 0.15))
                    catch.append(circ(px + er * 0.04, py - er * 0.06, er * 0.045))
                else:  # bead
                    eyes.append(circ(x, eye_y + er * 0.02, er * 0.085))
                    catch.append(circ(x + er * 0.03, eye_y - er * 0.015, er * 0.026))
            if e == "Encouraging" and s.eyes != "white":
                eyes = [move(g, -er * 0.03, -er * 0.05) for g in eyes]
                catch = [move(g, -er * 0.03, -er * 0.05) for g in catch]
        elif e in ("Happy", "Celebrating"):
            for x in ex:
                w = er * (0.16 if s.eyes != "bead" else 0.12)
                lw2 = er * (0.07 if s.eyes == "white" else 0.06)
                eyes.append(stroke(arc_pts(x, eye_y + w * 0.45, w, w * 0.85, 200, 340, 14), lw2))
        else:  # Sleepy: closed downward arcs
            for x in ex:
                w = er * (0.15 if s.eyes != "bead" else 0.11)
                eyes.append(stroke(arc_pts(x, eye_y - w * 0.15, w, w * 0.7, 20, 160, 14), er * 0.055))
        eye_key = "mascotFeatures"
        if s.eyes == "white" and e in ("Happy", "Celebrating", "Sleepy"):
            eye_key = ew_key

        nx, ny = nose_c
        nw = hr * (0.13 if s.eyes != "bead" else 0.1)
        nose = Polygon([(nx - nw, ny - nw * 0.55), (nx + nw, ny - nw * 0.55), (nx, ny + nw * 0.6)]).buffer(
            nw * 0.28, resolution=RES)
        my = ny + nw * 0.85
        mouth, tongue = None, None
        mw = hr * 0.075
        lwm = hr * 0.055
        if e == "Idle":
            if s.eyes == "bead":
                mouth = stroke(arc_pts(nx, my - mw * 0.6, mw * 1.3, mw * 0.8, 30, 150, 12), lwm)
            else:
                mouth = unary_union([stroke(arc_pts(nx - mw, my, mw, mw * 0.9, 10, 170, 10), lwm),
                                     stroke(arc_pts(nx + mw, my, mw, mw * 0.9, 10, 170, 10), lwm)])
        elif e in ("Happy", "Celebrating"):
            big_m = 1.25 if e == "Celebrating" else 1.0
            m = ell(nx, my + mw * 0.1, mw * 2.1 * big_m, mw * 2.0 * big_m).intersection(
                box(nx - 50, my, nx + 50, my + 50))
            mouth = m.buffer(lwm * 0.15, resolution=RES)
            tongue = ell(nx, my + mw * 1.55 * big_m, mw * 1.1 * big_m, mw * 0.75 * big_m).intersection(m)
        elif e == "Encouraging":
            mouth = stroke(arc_pts(nx, my - mw * 0.4, mw * 1.6, mw * 1.1, 25, 155, 12), lwm)
        elif e == "Sleepy":
            mouth = stroke([(nx - mw * 0.7, my + mw * 0.3), (nx + mw * 0.7, my + mw * 0.3)], lwm)
        else:  # Hello
            mouth = ell(nx, my + mw * 0.6, mw * 0.85, mw * 1.0)

        cheeks = None
        if s.cheeks:
            cy = eye_y + hr * (0.3 if s.eyes != "white" else 0.36)
            cheeks = unary_union([ell(ex[0] - hr * 0.12, cy, hr * 0.15, hr * 0.095),
                                  ell(ex[1] + hr * 0.17, cy, hr * 0.13, hr * 0.09)])

        # ---- accessories
        collar, bell, petals, centres = None, None, None, None
        if self.stage >= 3 and e != "Sleepy":
            if s.collar == "ribbon":
                c0 = (hx - hr * 0.55, hy_l + hr * 0.92)
                c2 = (hx + hr * 0.95, hy_l + hr * 0.42)
                c1 = (hx + hr * 0.25, hy_l + hr * 1.35)
                collar = stroke(quad_pts(c0, c1, c2), hr * 0.24)
            else:  # bandana: a knotted triangle under the chin
                c0 = (hx - hr * 0.6, hy_l + hr * 0.86)
                c2 = (hx + hr * 0.92, hy_l + hr * 0.38)
                c1 = (hx + hr * 0.2, hy_l + hr * 1.3)
                band = stroke(quad_pts(c0, c1, c2), hr * 0.26)
                tri = Polygon([(hx - hr * 0.25, hy_l + hr * 1.0), (hx + hr * 0.5, hy_l + hr * 0.95),
                               (hx + hr * 0.02, hy_l + hr * 1.62)]).buffer(hr * 0.06, resolution=RES)
                collar = unary_union([band, tri])
            if self.stage >= 4:
                bc = (hx + hr * 0.2, hy_l + hr * (1.42 if s.collar == "ribbon" else 1.5))
                if s.collar == "bandana":
                    bc = (hx + hr * 0.62, hy_l + hr * 1.08)
                bell = circ(bc[0], bc[1], hr * 0.2).difference(
                    stroke([(bc[0] - hr * 0.1, bc[1] + hr * 0.06), (bc[0] + hr * 0.1, bc[1] + hr * 0.06)], hr * 0.04))
        if self.stage == 5:
            fl, fc = [], []
            for i, (dx, dy) in enumerate([(-0.72, -0.62), (-0.38, -0.92), (0.02, -1.02), (0.42, -0.9), (0.74, -0.58)]):
                cx, cy = hx + dx * hr, hy_l + dy * hr
                r0 = hr * 0.11
                fl.append(unary_union([circ(cx + r0 * 1.15 * math.cos(math.radians(a + i * 17)),
                                            cy + r0 * 1.15 * math.sin(math.radians(a + i * 17)), r0)
                                       for a in range(0, 360, 72)]))
                fc.append(circ(cx, cy, r0 * 0.8))
            petals, centres = unary_union(fl), unary_union(fc)

        head_parts = dict(ear_far=ear_far, ear_far_in=ear_far_in, head=head, tuft=tuft, ear_near=ear_near,
                          ear_near_in=ear_near_in, cheeks=cheeks, eyes=unary_union(eyes) if eyes else None,
                          whites=unary_union(whites) if whites else None,
                          catch=unary_union(catch) if catch else None, nose=nose, mouth=mouth, tongue=tongue,
                          petals=petals, centres=centres)
        if e == "Encouraging":
            pivot = (hx + hr * 0.3, hy_l + hr * 0.8)
            head_parts = {k: (rot(v, 10, pivot) if v is not None else None) for k, v in head_parts.items()}

        # Hello: one front hoof raised beside the cheek
        wave, wave_hoof = None, None
        if e == "Hello":
            # the leg starts hidden behind the chin and lifts out beside the cheek
            a0 = (hx - hr * 0.45, hy_l + hr * 0.95)
            a1 = (hx - hr * 1.28, hy_l + hr * 0.12)
            wave = stroke([a0, a1], lw * 1.05)
            wave_hoof = wave.intersection(circ(a1[0], a1[1], lw * 0.95))

        # ---- extras
        sparkles, zz = None, None
        if e == "Celebrating":
            sparkles = unary_union([star4(hx - hr * 1.15, hy_l - hr * 0.95, hr * 0.3),
                                    star4(hx + hr * 1.25, hy_l - hr * 1.2, hr * 0.24),
                                    star4(hx - hr * 1.35, hy_l + hr * 0.35, hr * 0.17)])
        if e == "Sleepy":
            def zed(x, y, h, w):
                return stroke([(x, y), (x + h, y), (x, y + h), (x + h, y + h)], w)
            zz = unary_union([zed(hx + hr * 0.7, hy_l - hr * 1.15, hr * 0.32, hr * 0.07),
                              zed(hx + hr * 1.15, hy_l - hr * 1.6, hr * 0.24, hr * 0.06)])

        # ---- shading
        shade = fleece.difference(move(fleece, -ry * 0.1, -ry * 0.3))
        curls = None
        if s.curls:
            cs = []
            for cx, cy, r in [(bx + rx * 0.12, by - ry * 0.18, ry * 0.2), (bx + rx * 0.55, by + ry * 0.12, ry * 0.17),
                              (bx - rx * 0.18, by + ry * 0.3, ry * 0.16)]:
                cs.append(stroke(arc_pts(cx, cy + lift, r, r, 150, 400, 18), ry * 0.07))
            curls = unary_union(cs).intersection(fleece.buffer(-1.5))

        ground = p["ground"]
        sh_scale = 0.78 if (e == "Celebrating" and p["pose"] == "lying") else 1.0
        shadow = ell(bx - rx * 0.12, ground + 1.2, (rx + hr * 0.5) * sh_scale, 3.0)

        # ---- assemble in paint order
        leg_key, far_key = s.leg_key, "mascotFarLegs"
        hp = head_parts
        self.add("Shadow", "mascotShadow", shadow)
        if s.outline:
            parts = [fleece, hp["head"], hp["ear_near"], hp["ear_far"]] + near_legs + far_legs
            for extra in (hp["tuft"], wave, collar, bell, hp["petals"]):
                if extra is not None:
                    parts.append(extra)
            self.add("Outline", "mascotOutline", unary_union(parts).buffer(s.outline, resolution=RES))
        self.add("FarLegs", far_key, unary_union(far_legs) if far_legs else None)
        self.add("NearLegs", leg_key, unary_union(near_legs) if near_legs else None)
        self.add("Hooves", "mascotHoof", unary_union(hooves) if hooves else None)
        self.add("Fleece", "mascotFleece", fleece)
        self.add("FleeceShade", "mascotFleeceShade", shade)
        if curls is not None:
            self.add("FleeceCurls", "mascotFleeceShade", curls)
        self.add("Ribbon", "accentFill", collar)
        self.add("Bell", "mascotBell", bell)
        self.add("EarFar", "mascotFace", hp["ear_far"])
        self.add("EarFarInner", "mascotBlush", hp["ear_far_in"])
        if wave is not None:
            self.add("WaveLeg", leg_key, wave)
            self.add("WaveHoof", "mascotHoof", wave_hoof)
        self.add("Head", "mascotFace", hp["head"])
        self.add("Tuft", "mascotFleece", hp["tuft"])
        self.add("EarNear", "mascotFace", hp["ear_near"])
        self.add("EarNearInner", "mascotBlush", hp["ear_near_in"])
        self.add("FlowerPetals", "mascotFlower", hp["petals"])
        self.add("FlowerCentres", "goldFill", hp["centres"])
        self.add("Cheeks", "mascotBlush", hp["cheeks"], 0.45 if s.eyes != "white" else 0.7)
        self.add("EyeWhites", ew_key, hp["whites"])
        self.add("Eyes", eye_key, hp["eyes"])
        self.add("Catchlights", "mascotCatchlight", hp["catch"])
        self.add("Nose", s.nose_key, hp["nose"])
        mouth_key = s.mouth_key
        if e in ("Happy", "Celebrating", "Hello") and s.eyes == "white":
            mouth_key = "mascotMouth"
        self.add("Mouth", mouth_key, hp["mouth"])
        self.add("Tongue", "mascotTongue", hp["tongue"])
        self.add("Sparkles", s.sparkle_key, sparkles)
        self.add("Zz", "mascotZz", zz)
        return self


# ---------------------------------------------------------------- front face (icon, mark)


def face_front(style_key: str, expr: str = "Idle"):
    """A symmetric, front-facing head for the app icon and the logo mark, in a 100 x 100 box."""
    s = STYLES[style_key]
    cx, hy = 50.0, 47.0
    hr = 24.0 * (1.06 if s.eyes == "white" else 1.0)
    head = hull2(circ(cx, hy, hr), circ(cx, hy + hr * 0.62, hr * 0.62))
    ear_a = 162 if expr != "Happy" else 176
    el, ew = hr * s.ear_len * 1.02, hr * s.ear_w
    ears, inners = [], []
    for side in (-1, 1):
        a = ear_a if side < 0 else 180 - ear_a
        rx_, ry_ = cx + side * hr * 0.8, hy - hr * 0.12
        ears.append(leaf(rx_, ry_, el, ew, a, s.ear_tip))
        inners.append(leaf(rx_ + math.cos(math.radians(a)) * ew * 0.42, ry_ + math.sin(math.radians(a)) * ew * 0.42,
                           el * 0.55, ew * 0.46, a, s.ear_tip))
    if s.tuft == "cap":
        pts = [(-0.56, -0.58, 0.33), (-0.24, -0.84, 0.38), (0.24, -0.84, 0.38), (0.56, -0.58, 0.33), (0, -0.62, 0.42),
               (0, -1.06, 0.3)]
        tuft = smooth(unary_union([circ(cx + dx * hr, hy + dy * hr, r * hr) for dx, dy, r in pts]), 1.2)
    elif s.tuft == "three":
        tuft = unary_union([circ(cx + dx * hr, hy - hr * 0.88, hr * 0.27) for dx in (-0.3, 0, 0.3)])
    else:
        tuft = ell(cx, hy - hr * 0.86, hr * 0.44, hr * 0.27)
    ey = hy + hr * (0.1 if s.eyes == "white" else 0.16)
    exs = [cx - hr * 0.37, cx + hr * 0.37]
    er = hr * s.eye_scale
    eyes, whites, catch = [], [], []
    for x in exs:
        if expr == "Happy":
            w = er * 0.16
            eyes.append(stroke(arc_pts(x, ey + w * 0.45, w, w * 0.85, 200, 340, 14), er * 0.065))
        elif s.eyes == "dot":
            eyes.append(ell(x, ey, er * 0.13, er * 0.165))
            catch.append(circ(x + er * 0.045, ey - er * 0.065, er * 0.05))
        elif s.eyes == "white":
            whites.append(ell(x, ey, er * 0.2, er * 0.235))
            eyes.append(ell(x, ey + er * 0.03, er * 0.125, er * 0.15))
            catch.append(circ(x + er * 0.04, ey - er * 0.04, er * 0.045))
        else:
            eyes.append(circ(x, ey, er * 0.085))
            catch.append(circ(x + er * 0.03, ey - er * 0.03, er * 0.026))
    nx, ny = cx, hy + hr * (0.6 if s.eyes == "white" else 0.54)
    nw = hr * 0.13
    nose = Polygon([(nx - nw, ny - nw * 0.55), (nx + nw, ny - nw * 0.55), (nx, ny + nw * 0.6)]).buffer(nw * 0.28,
                                                                                                         resolution=RES)
    my, mw, lwm = ny + nw * 0.85, hr * 0.075, hr * 0.055
    if expr == "Happy":
        m = ell(nx, my, mw * 2.1, mw * 2.0).intersection(box(nx - 50, my, nx + 50, my + 50))
        mouth = m.buffer(lwm * 0.15, resolution=RES)
        tongue = ell(nx, my + mw * 1.55, mw * 1.1, mw * 0.75).intersection(m)
    else:
        mouth = unary_union([stroke(arc_pts(nx - mw, my, mw, mw * 0.9, 10, 170, 10), lwm),
                             stroke(arc_pts(nx + mw, my, mw, mw * 0.9, 10, 170, 10), lwm)])
        tongue = None
    cheeks = None
    if s.cheeks:
        cy = ey + hr * (0.34 if s.eyes == "white" else 0.3)
        cheeks = unary_union([ell(x + side * hr * 0.1, cy, hr * 0.15, hr * 0.095) for x, side in zip(exs, (-1, 1))])
    mouth_key = s.mouth_key if not (expr == "Happy" and s.eyes == "white") else "mascotMouth"
    L = [("EarFar", "mascotFace", unary_union(ears), 1.0), ("EarInner", "mascotBlush", unary_union(inners), 1.0),
         ("Head", "mascotFace", head, 1.0), ("Tuft", "mascotFleece", tuft, 1.0),
         ("Cheeks", "mascotBlush", cheeks, 0.45 if s.eyes != "white" else 0.7),
         ("EyeWhites", "mascotEyeWhite", unary_union(whites) if whites else None, 1.0),
         ("Eyes", "mascotEyeWhite" if (s.eyes == "white" and expr == "Happy") else "mascotFeatures",
          unary_union(eyes), 1.0),
         ("Catchlights", "mascotCatchlight", unary_union(catch) if catch else None, 1.0),
         ("Nose", s.nose_key, nose, 1.0), ("Mouth", mouth_key, mouth, 1.0), ("Tongue", "mascotTongue", tongue, 1.0)]
    if s.outline:
        sil = unary_union([g for _, _, g, _ in L[:4]]).buffer(s.outline * 1.2, resolution=RES)
        L.insert(0, ("Outline", "mascotOutline", sil, 1.0))
    layers = [dict(name=n, fill=k, geometry=geom_to_path(g), **({"opacity": o} if o != 1 else {}))
              for n, k, g, o in L if g is not None and not g.is_empty]
    sil = unary_union([g for n, _, g, _ in L if n in ("EarFar", "Head", "Tuft")])
    return {"viewBox": [0, 0, 100, 100], "layers": layers, "silhouette": geom_to_path(sil),
            "bounds": [round(v, 2) for v in sil.bounds]}


# ---------------------------------------------------------------- output


def geom_to_path(g, ndigits=1):
    if g.is_empty:
        return ""
    polys = [g] if isinstance(g, Polygon) else [x for x in getattr(g, "geoms", []) if isinstance(x, Polygon)]
    out = []
    for poly in polys:
        poly = orient(poly.simplify(0.06, preserve_topology=True), 1.0)
        for ring in [poly.exterior] + list(poly.interiors):
            pts = list(ring.coords)[:-1]
            if len(pts) < 3:
                continue
            q = [(round(x, ndigits), round(y, ndigits)) for x, y in pts]
            s = [f"M{_f(q[0][0])} {_f(q[0][1])}l"]
            px, py = q[0]
            first = True
            for x, y in q[1:]:
                dx, dy = round(x - px, ndigits), round(y - py, ndigits)
                if dx == 0 and dy == 0:
                    continue
                s.append(("" if first else _sep(dx)) + _f(dx) + _sep(dy) + _f(dy))
                first = False
                px, py = round(px + dx, ndigits), round(py + dy, ndigits)
            s.append("z")
            out.append("".join(s))
    return "".join(out)


def _f(v):
    t = f"{v:.1f}".rstrip("0").rstrip(".")
    return "0" if t in ("-0", "") else t


def _sep(v):
    return "" if v < 0 else " "


def union_bounds(geoms, pad=2.0):
    u = unary_union([g for g in geoms if g is not None and not g.is_empty])
    minx, miny, maxx, maxy = u.bounds
    return [math.floor(minx - pad), math.floor(miny - pad), math.ceil(maxx - minx + 2 * pad),
            math.ceil(maxy - miny + 2 * pad)]


PT_PER_UNIT = 1.1


def build_stage(style: Style, stage: int):
    variants = {e: Lamb(style, stage, e).build() for e in EXPRESSIONS}
    # one shared viewBox per stage so instances swap without jumping
    vb = union_bounds([g for v in variants.values() for (_, _, g, _) in v.layers], pad=2.5)
    out = {"stage": stage, "name": STAGE_NAMES[stage], "width": round(vb[2] * PT_PER_UNIT, 1),
           "height": round(vb[3] * PT_PER_UNIT, 1), "viewBox": vb, "expressions": {}}
    for e, v in variants.items():
        out["expressions"][e] = [dict(name=n, fill=k, geometry=geom_to_path(g), **({"opacity": o} if o != 1 else {}))
                                 for (n, k, g, o) in v.layers]
    return out, variants


AVATAR_KEYS = [(1, "Happy"), (1, "Encouraging"), (1, "Idle"), (2, "Idle"), (3, "Idle"), (4, "Idle"), (5, "Idle")]


def build_avatar(style: Style, stage: int, expr: str):
    lamb = Lamb(style, stage, expr).build()
    p = lamb.p
    hr = p["hr"]
    # centre the head (slightly left of centre, shoulders in frame), head radius -> 15.5 of 56
    k = 15.5 / hr
    cx, cy = p["hx"] + hr * 0.25, p["hy"] + hr * 0.25 + (-3 if expr == "Happy" else 0)
    clip = circ(28, 28, 28)
    layers = []
    for (n, key, g, o) in lamb.layers:
        if n in ("Shadow", "Zz", "Sparkles"):
            continue
        t = affinity.translate(affinity.scale(g, k, k, origin=(cx, cy)), 28 - cx, 30 - cy)
        t = t.intersection(clip)
        if t.is_empty:
            continue
        d = dict(name=n, fill=key, geometry=geom_to_path(t))
        if o != 1:
            d["opacity"] = o
        layers.append(d)
    return {"width": 56, "height": 56, "viewBox": [0, 0, 56, 56], "layers": layers}


def build_glyph(style: Style):
    lamb = Lamb(style, 3, "Idle").build()
    by = {n: g for (n, _, g, _) in lamb.layers}
    head_group = unary_union([g for n, g in by.items() if n in ("Head", "EarNear", "EarFar", "Tuft")])
    body = unary_union([g for n, g in by.items() if n in ("Fleece", "NearLegs", "FarLegs")])
    sil = unary_union([body.difference(head_group.buffer(2.6, resolution=RES)), head_group])
    # face cut-outs: the eyes (and eye whites) read as holes in the template
    holes = [g for n, g in by.items() if n in ("Eyes", "EyeWhites")]
    if holes:
        sil = sil.difference(unary_union(holes).buffer(0.9, resolution=RES))
    sil = smooth(sil, 0.6)
    vb = union_bounds([sil], pad=0.2)
    return {"width": 24, "height": 24, "viewBox": [float(v) for v in vb], "fill": "accent",
            "geometry": geom_to_path(sil)}


def build_all(style_key: str):
    style = STYLES[style_key]
    data = {"style": style_key, "stages": {}, "avatars": {}}
    for st in range(1, 6):
        data["stages"][str(st)], _ = build_stage(style, st)
    for st, e in AVATAR_KEYS:
        data["avatars"][f"S{st}/{e}"] = build_avatar(style, st, e)
    data["glyph"] = build_glyph(style)
    return data


# ---------------------------------------------------------------- svg preview


def svg_layers(layers, palette, transform=""):
    out = []
    for l in layers:
        try:
            col = palette[l["fill"]]
        except KeyError:
            col = "#FF00FF"
        op = l.get("opacity", 1)
        out.append(f'<path d="{l["geometry"]}" fill="{col}"' + (f' fill-opacity="{op}"' if op != 1 else "") + "/>")
    return f'<g transform="{transform}">' + "".join(out) + "</g>"


def svg_variant(data, stage, expr, palette, height_px, x=0, y=0):
    st = data["stages"][str(stage)]
    vx, vy, vw, vh = st["viewBox"]
    s = height_px / vh
    return svg_layers(st["expressions"][expr], palette, f"translate({x},{y}) scale({s}) translate({-vx},{-vy})"), vw * s


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--style", required=True, choices=sorted(STYLES))
    ap.add_argument("--out", required=True)
    a = ap.parse_args()
    d = build_all(a.style)
    with open(a.out, "w") as f:
        json.dump(d, f, separators=(",", ":"))
    print(f"wrote {a.out}: {sum(len(v['expressions']) for v in d['stages'].values())} variants, "
          f"{len(d['avatars'])} avatars, glyph")
