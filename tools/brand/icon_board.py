#!/usr/bin/env python3
"""Generate the app icon presentation board showing default and dark icons at 180px and 60px on light and dark wallpapers."""

import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SET = os.path.join(ROOT, "Shepherd/Resources/Assets.xcassets/AppIcon.appiconset")
OUT = os.path.join(ROOT, "docs/brand/icon_board.png")
SF = "/System/Library/Fonts/SFNS.ttf"

def squircle(img, px):
    img = img.convert("RGBA").resize((px, px), Image.LANCZOS)
    m = Image.new("L", (px * 4, px * 4), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, px * 4 - 1, px * 4 - 1], radius=int(px * 4 * 0.2237), fill=255)
    img.putalpha(m.resize((px, px), Image.LANCZOS))
    return img

def wallpaper(w, h, top, bot):
    g = Image.new("RGB", (1, 256))
    for i in range(256):
        t = i / 255
        g.putpixel((0, i), tuple(round(top[c] * (1 - t) + bot[c] * t) for c in range(3)))
    return g.resize((w, h)).convert("RGBA")

def main():
    icon_light = Image.open(os.path.join(SET, "AppIcon.png"))
    icon_dark = Image.open(os.path.join(SET, "AppIcon-Dark.png"))

    # Board layout:
    # 2 sections: Light Wallpaper, Dark Wallpaper
    # Each section shows Default icon (180px, 60px) and Dark icon (180px, 60px) with labels
    card_w, card_h = 600, 360
    total_w = card_w * 2 + 60
    total_h = card_h + 100

    board = Image.new("RGBA", (total_w, total_h), (28, 28, 30, 255))
    dr = ImageDraw.Draw(board)
    f_title = ImageFont.truetype(SF, 24)
    f_label = ImageFont.truetype(SF, 18)
    f_caption = ImageFont.truetype(SF, 14)

    dr.text((30, 25), "App Icon — Green Pastures (Default & Dark appearances at 180 px & 60 px)", font=f_title, fill=(240, 240, 240, 255))

    # 1. Light Wallpaper Card
    wp_light = wallpaper(card_w, card_h, (214, 228, 244), (246, 232, 218))
    dr_l = ImageDraw.Draw(wp_light)
    dr_l.text((20, 16), "Light Wallpaper", font=f_label, fill=(30, 30, 30, 255))

    # Light icon 180px
    ic_l_180 = squircle(icon_light, 180)
    wp_light.alpha_composite(ic_l_180, (40, 60))
    dr_l.text((130, 260), "Default (180 px)", font=f_caption, fill=(40, 40, 40, 255), anchor="mt")

    # Light icon 60px
    ic_l_60 = squircle(icon_light, 60)
    wp_light.alpha_composite(ic_l_60, (260, 120))
    dr_l.text((290, 200), "60 px", font=f_caption, fill=(40, 40, 40, 255), anchor="mt")

    # Dark icon on light wallpaper 180px
    ic_d_180 = squircle(icon_dark, 180)
    wp_light.alpha_composite(ic_d_180, (360, 60))
    dr_l.text((450, 260), "Dark (180 px)", font=f_caption, fill=(40, 40, 40, 255), anchor="mt")

    # 2. Dark Wallpaper Card
    wp_dark = wallpaper(card_w, card_h, (20, 24, 33), (44, 49, 64))
    dr_d = ImageDraw.Draw(wp_dark)
    dr_d.text((20, 16), "Dark Wallpaper", font=f_label, fill=(240, 240, 240, 255))

    # Dark icon 180px
    wp_dark.alpha_composite(ic_d_180, (40, 60))
    dr_d.text((130, 260), "Dark (180 px)", font=f_caption, fill=(220, 220, 220, 255), anchor="mt")

    # Dark icon 60px
    ic_d_60 = squircle(icon_dark, 60)
    wp_dark.alpha_composite(ic_d_60, (260, 120))
    dr_d.text((290, 200), "60 px", font=f_caption, fill=(220, 220, 220, 255), anchor="mt")

    # Light icon on dark wallpaper 180px
    wp_dark.alpha_composite(ic_l_180, (360, 60))
    dr_d.text((450, 260), "Default (180 px)", font=f_caption, fill=(220, 220, 220, 255), anchor="mt")

    # Paste cards onto board
    board.alpha_composite(wp_light, (20, 70))
    board.alpha_composite(wp_dark, (card_w + 40, 70))

    board.save(OUT, "PNG")
    print(f"Generated {OUT}")

if __name__ == "__main__":
    main()
