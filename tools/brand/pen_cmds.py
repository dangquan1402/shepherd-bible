"""Emit `pen interactive` command files that apply a brand direction to a .pen library + screens.

    python3 tools/brand/pen_cmds.py lib  <direction> <lib.pen>     > lib.cmds
    python3 tools/brand/pen_cmds.py screens <direction> <lib.pen> <screens.pen> [frame ...] > screens.cmds

lib: sets every colour token (light/dark) and rebuilds the 30 lamb components, the 7 avatars and the
tab glyph from tools/brand/lambgen.py, keeping every component id so instances stay linked.
screens: re-sizes each lamb/avatar instance to the new aspect ratio (descendant overrides keyed by
the new, unique layer names).
"""

from __future__ import annotations

import json
import re
import sys

sys.path.insert(0, __import__("os").path.dirname(__file__))
import lambgen
import tokens as T


def read_json(path):
    with open(path) as f:
        return json.load(f)


def var(key):
    return "--color-" + re.sub(r"(?<!^)([A-Z])", r"-\1", key).lower()


def ex(js):
    return "execute({ input: " + json.dumps(js) + " })"


def walk(n):
    yield n
    for c in n.get("children", []) or []:
        yield from walk(c)


def comp_ids(lib):
    out = {}
    for t in lib["children"]:
        for n in walk(t):
            if n.get("reusable"):
                out[n["name"]] = n["id"]
    return out


def set_variables(direction):
    tk = T.tokens(direction)
    vs = {}
    for k, (lt, dk) in tk.items():
        vs[k] = {
            "type": "color",
            "value": [{"value": lt, "theme": {"mode": "light"}}, {"value": dk, "theme": {"mode": "dark"}}],
        }
    return ex("SetVariables(" + json.dumps(vs) + ")")


def path_nodes(layers, vb, w, h, prefix=""):
    nodes = []
    for l in layers:
        n = {
            "type": "path",
            "name": l["name"],
            "x": 0,
            "y": 0,
            "geometry": l["geometry"],
            "viewBox": vb,
            "fill": f"${prefix}{var(l['fill'])}",
            "width": w,
            "height": h,
        }
        if l.get("opacity", 1) != 1:
            n["opacity"] = l["opacity"]
        nodes.append(n)
    return nodes


def rebuild(cid, nodes, w, h):
    return ex(
        f"c={json.dumps(cid)};(Get(c,{{depth:1}}).children||[]).forEach(ch=>Delete(ch.id));"
        f"Update(c,{{width:{w},height:{h}}});"
        f"{json.dumps(nodes)}.forEach(n=>Insert(c,n))"
    )


def lib_cmds(direction, lib_path):
    lib = read_json(lib_path)
    ids = comp_ids(lib)
    data = lambgen.build_all(direction)
    out = [set_variables(direction)]
    for s, st in data["stages"].items():
        vb, w, h = st["viewBox"], st["width"], st["height"]
        for e, layers in st["expressions"].items():
            out.append(rebuild(ids[f"Lamb/S{s}/{e}"], path_nodes(layers, vb, w, h), w, h))
    for key, av in data["avatars"].items():
        out.append(rebuild(ids[f"Avatar/{key}"], path_nodes(av["layers"], av["viewBox"], 56, 56), 56, 56))
    g = data["glyph"]
    _, _, vw, vh = g["viewBox"]
    k = 24 / max(vw, vh)
    gw, gh = round(vw * k, 2), round(vh * k, 2)
    node = {
        "type": "path",
        "name": "Glyph",
        "x": round((24 - gw) / 2, 2),
        "y": round((24 - gh) / 2, 2),
        "geometry": g["geometry"],
        "viewBox": g["viewBox"],
        "fill": "$--color-text-tertiary",
        "width": gw,
        "height": gh,
    }
    # keep the glyph child's id: tab bars override its fill by id
    upd = {k: v for k, v in node.items() if k not in ("type", "name", "fill")}
    out.append(
        ex(f"c={json.dumps(ids['Icon/LambGlyph'])};ch=Get(c,{{depth:1}}).children[0];Update(ch.id,{json.dumps(upd)})")
    )
    return out, data


def screens_cmds(direction, lib_path, screens_path, frames):
    lib = read_json(lib_path)
    ids = comp_ids(lib)
    names = {v: k for k, v in ids.items()}
    data = lambgen.build_all(direction)
    doc = read_json(screens_path)
    out = []
    for top in doc["children"]:
        if frames and top["name"] not in frames:
            continue
        for n in walk(top):
            if n.get("type") != "ref":
                continue
            cname = names.get(n["ref"].split(":")[-1], "")
            m = re.match(r"(Lamb|Avatar)/S(\d)/(\w+)", cname)
            if not m:
                continue
            kind, s, e = m.groups()
            if kind == "Lamb":
                st = data["stages"][s]
                layers = st["expressions"][e]
                ar = st["width"] / st["height"]
            else:
                layers = data["avatars"][f"S{s}/{e}"]["layers"]
                ar = 1.0
            old_w = n.get("width") or 0
            old_h = n.get("height") or 0
            x, y = n.get("x", 0), n.get("y", 0)
            if kind == "Lamb" and old_w and old_h:
                nh = old_h
                nw = nh * ar
                if nw > old_w * 1.05:
                    nw = old_w * 1.05
                    nh = nw / ar
                nx = x + (old_w - nw) / 2
                ny = y + (old_h - nh)  # keep the feet on the same ground line
            else:
                nw = nh = old_w or 56
                nx, ny = x, y
            nw, nh = round(nw, 2), round(nh, 2)
            desc = {l["name"]: {"width": nw, "height": nh} for l in layers}
            upd = {"descendants": desc}
            if kind == "Lamb":
                upd.update({"x": round(nx, 2), "y": round(ny, 2), "width": nw, "height": nh})
            node = {"type": "ref", "ref": n["ref"], "name": n.get("name", cname)}
            for k in ("x", "y", "width", "height", "rotation", "opacity", "layoutPosition"):
                if k in n:
                    node[k] = n[k]
            node.update(upd)
            out.append(ex(f"Replace({json.dumps(n['id'])},{json.dumps(node)})"))
    return out


if __name__ == "__main__":
    mode = sys.argv[1]
    if mode == "lib":
        cmds, _ = lib_cmds(sys.argv[2], sys.argv[3])
    else:
        cmds = screens_cmds(sys.argv[2], sys.argv[3], sys.argv[4], " ".join(sys.argv[5:]).split())
    print("\n".join(cmds))
