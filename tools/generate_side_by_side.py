import os
from PIL import Image, ImageDraw, ImageFont

EXPORT_DIR = "design/exports"
SHOT_DIR = "docs/screenshots"
COMPARE_DIR = "docs/screenshots/compare"

os.makedirs(COMPARE_DIR, exist_ok=True)

files = [f for f in os.listdir(SHOT_DIR) if f.endswith(".png") and not f.startswith("Motion_")]

generated = 0
for f in sorted(files):
    app_path = os.path.join(SHOT_DIR, f)
    export_path = os.path.join(EXPORT_DIR, f)
    if not os.path.exists(export_path):
        continue

    app_img = Image.open(app_path).convert("RGBA")
    exp_img = Image.open(export_path).convert("RGBA")

    # Target height is app_img.height
    target_height = app_img.height
    if exp_img.height != target_height:
        scale = target_height / exp_img.height
        new_width = int(exp_img.width * scale)
        exp_img = exp_img.resize((new_width, target_height), Image.Resampling.LANCZOS)

    # Combined width
    gap = 20
    combined_width = exp_img.width + app_img.width + gap
    canvas = Image.new("RGBA", (combined_width, target_height + 80), (30, 30, 32, 255))

    # Paste images
    canvas.paste(exp_img, (0, 80))
    canvas.paste(app_img, (exp_img.width + gap, 80))

    # Add header labels
    draw = ImageDraw.Draw(canvas)
    # Draw simple text
    draw.text((20, 25), "DESIGN (Pencil Export)", fill=(200, 200, 200, 255))
    draw.text((exp_img.width + gap + 20, 25), "IMPLEMENTATION (SwiftUI Liquid Glass)", fill=(200, 200, 200, 255))

    out_path = os.path.join(COMPARE_DIR, f)
    canvas.save(out_path, "PNG")
    generated += 1
    print(f"Generated comparison: {f}")

print(f"Total side-by-side comparisons generated: {generated}")
