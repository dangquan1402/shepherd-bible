"""Emit the `pen interactive` commands that apply the Flock brand to design/.

    python3 tools/brand/apply_design.py lib     > lib.cmds      # tokens, lamb/avatar/glyph, Brand/* components
    python3 tools/brand/apply_design.py screens > screens.cmds  # every lamb instance, lockups, Mascot/Brand system

Run lib first and save it; screens reads the saved library for component ids.
Needs shapely (lambgen). The wordmark comes from tools/brand/wordmark.json (outlined Baloo 2, OFL).
"""

from __future__ import annotations

import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lambgen
import pen_cmds as P
import tokens as T

ROOT = os.path.dirname(os.path.dirname(HERE))
LIB = os.path.join(ROOT, "design/shepherd.lib.pen")
SCREENS = os.path.join(ROOT, "design/screens/shepherd.pen")
DIRECTION = "pasture"
MASCOT_STYLE = "flock"
WORD = P.read_json(os.path.join(HERE, "wordmark.json"))

MARK = 40  # Brand/Mark and Brand/Lockup
MARK_SM = 30  # Brand/Lockup/Compact
WORD_H = 30
WORD_H_SM = 21


def walk(n, parent=None):
    yield n, parent
    for c in n.get("children", []) or []:
        yield from walk(c, n)


def face_nodes(size, prefix, chip_fill=None, scale=0.8, dy=0.04):
    face = lambgen.face_front(MASCOT_STYLE, "Idle")
    x0, y0, x1, y1 = face["bounds"]
    fw, fh = x1 - x0, y1 - y0
    k = size * scale / max(fw, fh)
    pw, ph = round(fw * k, 2), round(fh * k, 2)
    nodes = []
    if chip_fill:
        nodes.append(
            {
                "type": "ellipse",
                "name": "Chip",
                "x": 0,
                "y": 0,
                "width": size,
                "height": size,
                "fill": f"${prefix}{chip_fill}",
            }
        )
    for l in face["layers"]:
        n = {
            "type": "path",
            "name": l["name"],
            "geometry": l["geometry"],
            "viewBox": [x0, y0, fw, fh],
            "x": round((size - pw) / 2, 2),
            "y": round((size - ph) / 2 + size * dy, 2),
            "width": pw,
            "height": ph,
            "fill": f"${prefix}{P.var(l['fill'])}",
        }
        if l.get("opacity", 1) != 1:
            n["opacity"] = l["opacity"]
        nodes.append(n)
    return nodes


def word_node(h, prefix, name="Letters"):
    mx, my, mw, mh = WORD["bbox"]
    w = round(mw * h / mh, 2)
    return {
        "type": "path",
        "name": name,
        "geometry": WORD["d"],
        "viewBox": [mx, my, mw, mh],
        "x": 0,
        "y": 0,
        "width": w,
        "height": h,
        "fill": f"${prefix}--color-accent",
    }, w


def lockup_children(mark, word_h, prefix):
    nodes = [dict(n, name="Mark" + n["name"]) for n in face_nodes(mark, prefix, "--color-accent-fill")]
    wn, ww = word_node(word_h, prefix, "Wordmark")
    gap = round(mark * 0.28, 2)
    wn.update(x=mark + gap, y=round((mark - word_h) / 2 + word_h * 0.08, 2))
    nodes.append(wn)
    return nodes, round(mark + gap + ww, 2), mark


# ------------------------------------------------------------------ lib


def ensure_component(name, frame, children, ids, at):
    """Create (or rebuild in place, keeping the id) a reusable frame with the given children."""
    if name in ids:
        cid = ids[name]
        return P.ex(
            f"c={json.dumps(cid)};(Get(c,{{depth:1}}).children||[]).forEach(ch=>Delete(ch.id));"
            f"Update(c,{json.dumps({k: v for k, v in frame.items() if k not in ('type', 'name', 'reusable')})});"
            f"{json.dumps(children)}.forEach(n=>Insert(c,n))"
        )
    node = dict(frame, name=name, reusable=True, x=at[0], y=at[1])
    return P.ex(
        'if(typeof BRAND==="undefined"){BRAND=Get(n=>n.name==="Board/Brand"?n.id:undefined)[0]};'
        f"c=Insert(BRAND,{json.dumps(node)});{json.dumps(children)}.forEach(n=>Insert(c,n))"
    )


def lib_cmds():
    lib = P.read_json(LIB)
    ids = P.comp_ids(lib)
    out, data = P.lib_cmds(DIRECTION, LIB, MASCOT_STYLE)
    # re-centre the character sheet's 30 lamb refs in their cells (feet on the old ground line)
    names = {v: k for k, v in ids.items()}
    old = {}
    for t in lib["children"]:
        for n, _ in walk(t):
            if n.get("reusable") and re.match(r"Lamb/S\d/\w+$", n["name"]):
                old[n["id"]] = (n["width"], n["height"])
    for t in lib["children"]:
        for n, par in walk(t):
            if n.get("type") == "ref" and par is not None and par.get("name") == "Mascot/CharacterSheet":
                m = re.match(r"Lamb/S(\d)/(\w+)", names.get(n["ref"], ""))
                if not m:
                    continue
                ow, oh = old[n["ref"]]
                st = data["stages"][m.group(1)]
                nx = n["x"] + (ow - st["width"]) / 2
                ny = n["y"] + (oh - st["height"])
                out.append(P.ex(f"Update({json.dumps(n['id'])},{{x:{round(nx, 2)},y:{round(ny, 2)}}})"))
    # the Brand board (created once)
    if not any(t.get("name") == "Board/Brand" for t in lib["children"]):
        out.append(
            P.ex(
                's=FindEmptySpace({width:1240,height:520,direction:"bottom",padding:200});'
                'BRAND=Insert(document,{type:"frame",name:"Board/Brand",x:s.x,y:s.y,width:1240,height:520,'
                'layout:"none",fill:"$--color-canvas-bg"});'
                'Insert(BRAND,{type:"text",name:"BoardTitle",x:24,y:16,content:"Brand: mark, wordmark, lockups, '
                'app icon (components)",fontFamily:"$--font-body",fontSize:15,fill:"$--color-text-secondary"})'
            )
        )
    comps = []
    comps.append(
        (
            "Brand/Mark",
            {"type": "frame", "width": MARK, "height": MARK, "layout": "none"},
            face_nodes(MARK, "", "--color-accent-fill"),
            (24, 60),
        )
    )
    wn, ww = word_node(WORD_H, "")
    comps.append(
        ("Brand/Wordmark", {"type": "frame", "width": ww, "height": WORD_H, "layout": "none"}, [wn], (100, 65))
    )
    lc, lw, lh = lockup_children(MARK, WORD_H, "")
    comps.append(("Brand/Lockup", {"type": "frame", "width": lw, "height": lh, "layout": "none"}, lc, (420, 60)))
    lc2, lw2, lh2 = lockup_children(MARK_SM, WORD_H_SM, "")
    comps.append(
        ("Brand/Lockup/Compact", {"type": "frame", "width": lw2, "height": lh2, "layout": "none"}, lc2, (780, 65))
    )
    icon = {
        "type": "frame",
        "width": 180,
        "height": 180,
        "layout": "none",
        "cornerRadius": 40.3,
        "clip": True,
        "fill": {
            "type": "gradient",
            "gradientType": "linear",
            "rotation": 180,
            "colors": [{"color": "$--color-icon-top", "position": 0}, {"color": "$--color-icon-bottom", "position": 1}],
        },
    }
    comps.append(("Brand/AppIcon", icon, face_nodes(180, "", None, scale=0.9, dy=46 / 1024), (24, 160)))
    for name, frame, children, at in comps:
        out.append(ensure_component(name, frame, children, ids, at))
    return out


# ------------------------------------------------------------------ screens

MASCOT_TEXT = {
    "Palette: fixed fills in both themes; only the outline changes": "Palette: fixed fills in both themes, no outline. The bandana follows the accent.",
}
SWATCH = [  # (swatch name, new token, label)
    ("Swatch Fleece", "--color-mascot-fleece", "Fleece / cap"),
    ("Swatch Fleece shade", "--color-mascot-fleece-shade", "Fleece shade / curls"),
    ("Swatch Face / ears", "--color-mascot-face", "Face / ears / legs"),
    ("Swatch Features / legs", "--color-mascot-features", "Pupils"),
    ("Swatch Blush / inner ear", "--color-mascot-blush", "Blush / inner ear / nose"),
    ("Swatch Outline", "--color-mascot-eye-white", "Eye white"),
    ("Swatch Accent ribbon", "--color-accent-fill", "Bandana (accent fill)"),
]


def screens_cmds():
    lib = P.read_json(LIB)
    ids = P.comp_ids(lib)
    doc = P.read_json(SCREENS)
    a = next(iter(doc.get("imports", {"I": ""})))
    pre = f"{a}:"
    out = P.screens_cmds(DIRECTION, LIB, SCREENS, [], MASCOT_STYLE)  # every lamb / avatar instance in every frame
    tk = T.tokens(DIRECTION)
    for top in doc["children"]:
        mode = (top.get("theme") or {}).get(f"{a}:mode", "light")
        mi = 0 if mode == "light" else 1
        nm = top["name"]
        if nm.startswith("Mascot_System_"):
            texts = {n.get("content"): n for n, _ in walk(top) if n.get("type") == "text"}
            for old, new in MASCOT_TEXT.items():
                if old in texts:
                    out.append(P.ex(f"Update({json.dumps(texts[old]['id'])},{json.dumps({'content': new})})"))
            for n, par in walk(top):
                for sw_name, token, label in SWATCH:
                    if n.get("name") == sw_name:
                        out.append(P.ex(f"Update({json.dumps(n['id'])},{json.dumps({'fill': '$' + pre + token})})"))
                        # the label is the next sibling text
                        sib = par["children"]
                        lab = sib[sib.index(n) + 1]
                        val = tk[token][mi][:7].upper()
                        out.append(
                            P.ex(f"Update({json.dumps(lab['id'])},{json.dumps({'content': f'{label}  {val}'})})")
                        )
        if nm.startswith(("Onboarding_Welcome_", "Paywall_Trial_")):
            if any(n.get("name") == "BrandLockup" for n, _ in walk(top)):
                continue
            sc = next(n for n, _ in walk(top) if n.get("name") == "ScrollContent")
            if nm.startswith("Onboarding_Welcome_"):
                _, w, _ = lockup_children(MARK, WORD_H, pre)
                node = {
                    "type": "ref",
                    "ref": f"{a}:{ids['Brand/Lockup']}",
                    "name": "BrandLockup",
                    "x": round((402 - w) / 2, 2),
                    "y": 116,
                }
            else:
                node = {
                    "type": "ref",
                    "ref": f"{a}:{ids['Brand/Lockup/Compact']}",
                    "name": "BrandLockup",
                    "x": 20,
                    "y": 64,
                }
            out.append(P.ex(f"Insert({json.dumps(sc['id'])},{json.dumps(node)})"))
    # Brand_System frames (light + dark), rebuilt on every run, beside Mascot_System
    for t_ in doc["children"]:
        if t_["name"].startswith("Brand_System_"):
            out.append(P.ex(f"Delete({json.dumps(t_['id'])})"))
    if True:
        ms = {t["name"]: t for t in doc["children"] if t["name"].startswith("Mascot_System_")}
        for mode in ("light", "dark"):
            base = ms[f"Mascot_System_{mode.capitalize()}"]
            x0 = base["x"] + 1240 * 2 + 400
            x = x0 if mode == "light" else x0 + 1340
            js = [
                (
                    f'f=Insert(document,{{type:"frame",name:"Brand_System_{mode.capitalize()}",x:{x},'
                    f'y:{base["y"]},width:1240,height:700,layout:"none",clip:true,fill:"${pre}--color-canvas-bg",'
                    f'theme:{{"{a}:mode":"{mode}"}}}});'
                )
            ]

            def t(x, y, s, size, weight="400", fill="--color-text-primary", font="--font-body", width=None):
                d = {
                    "type": "text",
                    "name": "Label",
                    "x": x,
                    "y": y,
                    "content": s,
                    "fontFamily": f"${pre}{font}",
                    "fontSize": size,
                    "fontWeight": weight,
                    "fill": f"${pre}{fill}",
                }
                if width:
                    d.update(textGrowth="fixed-width", width=width)
                return f"Insert(f,{json.dumps(d)});"

            def r(comp, x, y, **kw):
                d = {"type": "ref", "ref": f"{a}:{ids[comp]}", "name": comp.replace("/", " "), "x": x, "y": y}
                d.update(kw)
                return f"Insert(f,{json.dumps(d)});"

            js.append(t(40, 32, "The Pasture brand", 34, "600", font="--font-display"))
            js.append(
                t(
                    40,
                    82,
                    "Flock: ultramarine for action, sunflower for reward only, a black-faced lamb with a "
                    "fleece cap. Wordmark: Baloo 2 ExtraBold, outlined (SIL OFL 1.1); no font ships.",
                    17,
                    fill="--color-text-secondary",
                    width=1160,
                )
            )
            js.append(t(40, 150, "App icon", 15, "600"))
            js.append(r("Brand/AppIcon", 40, 186))
            js.append(
                t(
                    40,
                    380,
                    "180 px (60 pt @3x); this frame's theme is the icon's appearance",
                    13,
                    fill="--color-text-secondary",
                    width=300,
                )
            )
            js.append(t(400, 150, "Mark", 15, "600"))
            js.append(r("Brand/Mark", 400, 186))
            js.append(t(520, 150, "Wordmark", 15, "600"))
            js.append(r("Brand/Wordmark", 520, 191))
            js.append(t(400, 300, "Lockups", 15, "600"))
            js.append(r("Brand/Lockup", 400, 336))
            js.append(t(400, 390, "Onboarding welcome (centred above the lamb)", 13, fill="--color-text-secondary"))
            js.append(r("Brand/Lockup/Compact", 800, 341))
            js.append(t(800, 390, "Paywall header (top left)", 13, fill="--color-text-secondary"))
            js.append(
                t(
                    40,
                    480,
                    "iOS 26 appearances: default (light frame), dark (dark frame), tinted and clear are "
                    "generated from the same face (Shepherd/Resources/Assets.xcassets/AppIcon.appiconset, "
                    "docs/brand/icon_sheet.png). Sunflower never appears in routine chrome.",
                    15,
                    fill="--color-text-secondary",
                    width=1160,
                )
            )
            out.append(P.ex("".join(js)))
    return out


if __name__ == "__main__":
    cmds = lib_cmds() if sys.argv[1] == "lib" else screens_cmds()
    print("\n".join(c for c in cmds if c))
