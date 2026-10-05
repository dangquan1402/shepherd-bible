import json
import os
import subprocess

def main():
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    variants_path = os.path.join(repo_root, "Shepherd/Resources/Content/lamb_variants.json")
    icon_png_path = os.path.join(repo_root, "Shepherd/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png")

    with open(variants_path, "r") as f:
        data = json.load(f)

    stage3 = data["stages"]["3"]
    vb_x, vb_y, vb_w, vb_h = stage3["viewBox"]
    layers = stage3["expressions"]["Happy"]

    # Color map matching ShepherdTheme light tokens
    colors = {
        "mascotShadow": "rgba(0, 0, 0, 0.12)",
        "mascotOutline": "rgb(122, 102, 85)",
        "mascotFarLegs": "rgb(47, 38, 33)",
        "mascotFeatures": "rgb(61, 49, 43)",
        "mascotHoof": "rgb(36, 28, 24)",
        "mascotFleece": "rgb(255, 248, 236)",
        "mascotFleeceShade": "rgb(238, 226, 208)",
        "accentFill": "rgb(180, 83, 9)",
        "mascotFace": "rgb(244, 227, 204)",
        "mascotBlush": "rgb(239, 165, 147)",
        "mascotBell": "rgb(201, 154, 58)",
        "mascotTongue": "rgb(224, 127, 114)",
        "mascotEarInner": "rgb(239, 165, 147)",
        "white": "#FFFFFF"
    }

    icon_size = 1024
    target_lamb_w = 720.0
    scale = target_lamb_w / vb_w
    target_lamb_h = vb_h * scale

    x_offset = (icon_size - target_lamb_w) / 2.0
    y_offset = (icon_size - target_lamb_h) / 2.0 + 30.0  # slight optical center adjustment

    svg_layers = []
    for l in layers:
        fill_key = l.get("fill") or "accentFill"
        fill_color = colors.get(fill_key, "rgb(180, 83, 9)")
        geom = l["geometry"]
        svg_layers.append(f'    <path d="{geom}" fill="{fill_color}" fill-rule="evenodd" />')

    layers_str = "\n".join(svg_layers)

    svg_content = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{icon_size}" height="{icon_size}" viewBox="0 0 {icon_size} {icon_size}">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#FFF8E9" />
      <stop offset="100%" stop-color="#F7E8D5" />
    </linearGradient>
  </defs>
  <rect width="{icon_size}" height="{icon_size}" fill="url(#bg)" />
  <g transform="translate({x_offset:.4f}, {y_offset:.4f}) scale({scale:.6f}) translate({-vb_x:.4f}, {-vb_y:.4f})">
{layers_str}
  </g>
</svg>'''

    tmp_svg = "/tmp/app_icon_fixed.svg"
    with open(tmp_svg, "w") as f:
        f.write(svg_content)

    subprocess.run(["sips", "-s", "format", "png", tmp_svg, "--out", icon_png_path], check=True, capture_output=True)
    print(f"Generated clean AppIcon at {icon_png_path}")

if __name__ == "__main__":
    main()
