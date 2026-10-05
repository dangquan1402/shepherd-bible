import json
import os
import subprocess

def main():
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    variants_path = os.path.join(repo_root, "Shepherd/Resources/Content/lamb_variants.json")
    tab_lamb_dir = os.path.join(repo_root, "Shepherd/Resources/Assets.xcassets/TabLamb.imageset")

    with open(variants_path, "r") as f:
        data = json.load(f)

    glyph = data["glyph"]
    vb_x, vb_y, vb_w, vb_h = glyph["viewBox"]
    geom = glyph["geometry"]

    # Target 24x24 pt page with glyph scaled to fit (~20pt wide)
    page_size = 24.0
    target_w = 20.0
    scale = target_w / vb_w
    target_h = vb_h * scale
    x_offset = (page_size - target_w) / 2.0
    y_offset = (page_size - target_h) / 2.0

    svg_content = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{page_size}" height="{page_size}" viewBox="0 0 {page_size} {page_size}">
  <g transform="translate({x_offset:.4f}, {y_offset:.4f}) scale({scale:.6f}) translate({-vb_x:.4f}, {-vb_y:.4f})">
    <path d="{geom}" fill="#000000" fill-rule="evenodd"/>
  </g>
</svg>'''

    svg_path = os.path.join(tab_lamb_dir, "tab_lamb.svg")
    pdf_path = os.path.join(tab_lamb_dir, "tab_lamb.pdf")

    # Remove old PNGs
    for fn in ["tab_lamb.png", "tab_lamb@2x.png", "tab_lamb@3x.png"]:
        p = os.path.join(tab_lamb_dir, fn)
        if os.path.exists(p):
            os.remove(p)

    with open(svg_path, "w") as f:
        f.write(svg_content)
    print(f"Wrote {svg_path}")

    # Convert to vector PDF using sips
    subprocess.run(["sips", "-s", "format", "pdf", svg_path, "--out", pdf_path], check=True, capture_output=True)
    print(f"Generated {pdf_path}")

    # Write Contents.json for single universal vector image
    contents = {
        "images": [
            {
                "filename": "tab_lamb.pdf",
                "idiom": "universal"
            }
        ],
        "info": {
            "author": "xcode",
            "version": 1
        },
        "properties": {
            "preserves-vector-representation": True,
            "template-rendering-intent": "template"
        }
    }

    contents_path = os.path.join(tab_lamb_dir, "Contents.json")
    with open(contents_path, "w") as f:
        json.dump(contents, f, indent=2)
    print(f"Updated {contents_path}")

if __name__ == "__main__":
    main()
