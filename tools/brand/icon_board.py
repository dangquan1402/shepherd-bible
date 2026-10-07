#!/usr/bin/env python3
"""Generate the app icon presentation board showing Default, Dark, Tinted, and Clear icons at 180px and 60px on light and dark wallpapers."""

import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SET = os.path.join(ROOT, "Shepherd/Resources/Assets.xcassets/AppIcon.appiconset")
OUT = os.path.join(ROOT, "docs/brand/icon_board.png")
OUT_SHEET = os.path.join(ROOT, "docs/brand/icon_sheet.png")
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

def make_clear_icon(wp, x, y, size, icon_tinted):
    lum = icon_tinted.convert("L")
    wp_crop = wp.crop((x, y, x + size, y + size)).resize(lum.size, Image.LANCZOS)
    base = wp_crop.filter(ImageFilter.GaussianBlur(18))
    ic = Image.alpha_composite(base, Image.new("RGBA", lum.size, (255, 255, 255, 45)))
    ic.paste(Image.new("RGBA", lum.size, (255, 255, 255, 240)), (0, 0), lum.point(lambda v: min(255, int(v * 1.2))))
    return ic

def main():
    icon_light = Image.open(os.path.join(SET, "AppIcon.png"))
    icon_dark = Image.open(os.path.join(SET, "AppIcon-Dark.png"))
    icon_tinted = Image.open(os.path.join(SET, "AppIcon-Tinted.png"))

    card_w, card_h = 660, 540
    total_w = card_w * 2 + 60
    total_h = card_h + 90

    board = Image.new("RGBA", (total_w, total_h), (28, 28, 30, 255))
    dr = ImageDraw.Draw(board)
    f_title = ImageFont.truetype(SF, 24)
    f_label = ImageFont.truetype(SF, 18)
    f_caption = ImageFont.truetype(SF, 14)

    dr.text((30, 22), "App Icon — Green Pastures (Default, Dark, Tinted & Clear appearances at 180 px & 60 px)", font=f_title, fill=(240, 240, 240, 255))

    # 1. Light Wallpaper Card
    wp_light = wallpaper(card_w, card_h, (214, 228, 244), (246, 232, 218))
    dr_l = ImageDraw.Draw(wp_light)
    dr_l.text((25, 18), "Light Wallpaper", font=f_label, fill=(30, 30, 30, 255))

    # Row 1: Default & Dark
    wp_light.alpha_composite(squircle(icon_light, 180), (40, 55))
    dr_l.text((130, 245), "Default (180 px)", font=f_caption, fill=(40, 40, 40, 255), anchor="mt")
    wp_light.alpha_composite(squircle(icon_light, 60), (245, 115))
    dr_l.text((275, 185), "60 px", font=f_caption, fill=(40, 40, 40, 255), anchor="mt")

    wp_light.alpha_composite(squircle(icon_dark, 180), (355, 55))
    dr_l.text((445, 245), "Dark (180 px)", font=f_caption, fill=(40, 40, 40, 255), anchor="mt")
    wp_light.alpha_composite(squircle(icon_dark, 60), (560, 115))
    dr_l.text((590, 185), "60 px", font=f_caption, fill=(40, 40, 40, 255), anchor="mt")

    # Row 2: Tinted & Clear
    wp_light.alpha_composite(squircle(icon_tinted, 180), (40, 295))
    dr_l.text((130, 485), "Tinted / Greyscale (180 px)", font=f_caption, fill=(40, 40, 40, 255), anchor="mt")
    wp_light.alpha_composite(squircle(icon_tinted, 60), (245, 355))
    dr_l.text((275, 425), "60 px", font=f_caption, fill=(40, 40, 40, 255), anchor="mt")

    ic_clear_l_180 = make_clear_icon(wp_light, 355, 295, 180, icon_tinted)
    wp_light.alpha_composite(squircle(ic_clear_l_180, 180), (355, 295))
    dr_l.text((445, 485), "Clear (180 px)", font=f_caption, fill=(40, 40, 40, 255), anchor="mt")
    ic_clear_l_60 = make_clear_icon(wp_light, 560, 355, 60, icon_tinted)
    wp_light.alpha_composite(squircle(ic_clear_l_60, 60), (560, 355))
    dr_l.text((590, 425), "60 px", font=f_caption, fill=(40, 40, 40, 255), anchor="mt")

    # 2. Dark Wallpaper Card
    wp_dark = wallpaper(card_w, card_h, (20, 24, 33), (44, 49, 64))
    dr_d = ImageDraw.Draw(wp_dark)
    dr_d.text((25, 18), "Dark Wallpaper", font=f_label, fill=(240, 240, 240, 255))

    # Row 1: Dark & Default
    wp_dark.alpha_composite(squircle(icon_dark, 180), (40, 55))
    dr_d.text((130, 245), "Dark (180 px)", font=f_caption, fill=(220, 220, 220, 255), anchor="mt")
    wp_dark.alpha_composite(squircle(icon_dark, 60), (245, 115))
    dr_d.text((275, 185), "60 px", font=f_caption, fill=(220, 220, 220, 255), anchor="mt")

    wp_dark.alpha_composite(squircle(icon_light, 180), (355, 55))
    dr_d.text((445, 245), "Default (180 px)", font=f_caption, fill=(220, 220, 220, 255), anchor="mt")
    wp_dark.alpha_composite(squircle(icon_light, 60), (560, 115))
    dr_d.text((590, 185), "60 px", font=f_caption, fill=(220, 220, 220, 255), anchor="mt")

    # Row 2: Tinted & Clear
    wp_dark.alpha_composite(squircle(icon_tinted, 180), (40, 295))
    dr_d.text((130, 485), "Tinted / Greyscale (180 px)", font=f_caption, fill=(220, 220, 220, 255), anchor="mt")
    wp_dark.alpha_composite(squircle(icon_tinted, 60), (245, 355))
    dr_d.text((275, 425), "60 px", font=f_caption, fill=(220, 220, 220, 255), anchor="mt")

    ic_clear_d_180 = make_clear_icon(wp_dark, 355, 295, 180, icon_tinted)
    wp_dark.alpha_composite(squircle(ic_clear_d_180, 180), (355, 295))
    dr_d.text((445, 485), "Clear (180 px)", font=f_caption, fill=(220, 220, 220, 255), anchor="mt")
    ic_clear_d_60 = make_clear_icon(wp_dark, 560, 355, 60, icon_tinted)
    wp_dark.alpha_composite(squircle(ic_clear_d_60, 60), (560, 355))
    dr_d.text((590, 425), "60 px", font=f_caption, fill=(220, 220, 220, 255), anchor="mt")

    # Paste cards onto board
    board.alpha_composite(wp_light, (20, 65))
    board.alpha_composite(wp_dark, (card_w + 40, 65))

    board.save(OUT, "PNG")
    print(f"Generated {OUT}")
    board.save(OUT_SHEET, "PNG")
    print(f"Generated {OUT_SHEET}")

if __name__ == "__main__":
    main()

