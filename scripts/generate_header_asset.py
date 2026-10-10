#!/usr/bin/env python3
"""
Generate Sotto for iOS GitHub Header Banner / Social Preview
=============================================================
Dimensions:
  - 1280x640 (standard GitHub 2:1 ratio / Social Preview)
  - 2560x1280 (@2x Retina super-sampled master)

Design language:
  - Low-stimulus dark neutral palette (Charcoal #0E1114)
  - Sage green accent (#8EB292)
  - High-contrast WCAG AAA typography (Helvetica Neue / Apple System)
  - Authentic iPhone 16 Pro mockup with Dynamic Island
"""

import os
import sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

# Master 2x Canvas Dimensions
W2, H2 = 2560, 1280

def get_font_2x(size, bold=False):
    try:
        # Index 1 is Bold, Index 0 is Regular in macOS HelveticaNeue.ttc
        idx = 1 if bold else 0
        return ImageFont.truetype("/System/Library/Fonts/HelveticaNeue.ttc", size, index=idx)
    except Exception:
        try:
            name = "Arial Bold.ttf" if bold else "Arial.ttf"
            return ImageFont.truetype(f"/System/Library/Fonts/Supplemental/{name}", size)
        except Exception:
            return ImageFont.load_default()

def draw_badge_icon_2x(draw, icon_type, x, y, color):
    """Draw ultra-crisp 2x vector iconography inside feature badges."""
    w = 3 # line stroke width
    if icon_type == "partner":
        # Two connected human / speech nodes
        draw.ellipse([x, y + 4, x + 12, y + 16], fill=color)
        draw.ellipse([x + 16, y + 4, x + 28, y + 16], fill=color)
        draw.line([x + 6, y + 10, x + 22, y + 10], fill=color, width=w)
    elif icon_type == "tree":
        # Inquiry branching tree
        draw.line([x + 14, y + 4, x + 14, y + 26], fill=color, width=w)
        draw.line([x + 14, y + 12, x + 4, y + 6], fill=color, width=w)
        draw.line([x + 14, y + 18, x + 24, y + 10], fill=color, width=w)
        draw.ellipse([x + 2, y + 4, x + 8, y + 10], fill=color)
        draw.ellipse([x + 20, y + 8, x + 26, y + 14], fill=color)
    elif icon_type == "lock":
        # Privacy padlock
        draw.rounded_rectangle([x + 4, y + 10, x + 24, y + 27], radius=4, fill=color)
        draw.arc([x + 8, y + 1, x + 20, y + 16], start=180, end=0, fill=color, width=w)
    elif icon_type == "bolt":
        # Lightning bolt (Action Button & Siri)
        draw.polygon([
            (x + 16, y + 1),
            (x + 6, y + 14),
            (x + 14, y + 14),
            (x + 12, y + 28),
            (x + 24, y + 12),
            (x + 16, y + 12)
        ], fill=color)
    elif icon_type == "swift":
        # Swift diamond-bird flight emblem
        draw.polygon([
            (x + 4, y + 23),
            (x + 14, y + 4),
            (x + 24, y + 23),
            (x + 14, y + 17)
        ], fill=color)
    elif icon_type == "shield":
        # Security shield
        draw.polygon([
            (x + 4, y + 4),
            (x + 24, y + 4),
            (x + 24, y + 16),
            (x + 14, y + 27),
            (x + 4, y + 16)
        ], fill=color)

def generate_header_asset(
    output_path="assets/sotto_ios_banner.png",
    screenshot_path="assets/screenshots/iphone_medium_dynamic_island/01_aac_speech_board.png",
    icon_path="Sotto/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
):
    print("=== Generating Sotto for iOS Header Banner ===")
    
    # 1. Generate Smooth 2x Ambient Gradient Canvas (Charcoal Low-Stimulus)
    y_coords, x_coords = np.ogrid[:H2, :W2]
    
    # Base dark charcoal #0F1215 -> (15, 18, 21)
    base_r, base_g, base_b = 15.0, 18.0, 21.0
    
    # Ambient Sage Glow (Top-Left)
    dist_tl = np.sqrt(x_coords**2 + y_coords**2) / 1900.0
    factor_tl = np.clip(1.0 - dist_tl, 0.0, 1.0) ** 1.8
    glow_tl_r = factor_tl * 14.0
    glow_tl_g = factor_tl * 24.0
    glow_tl_b = factor_tl * 16.0
    
    # Subtle Soft Warm Amber/Charcoal vignette across the background
    dist_br = np.sqrt((x_coords - W2)**2 + (y_coords - H2)**2) / 2000.0
    factor_br = np.clip(1.0 - dist_br, 0.0, 1.0) ** 1.8
    glow_br_r = factor_br * 10.0
    glow_br_g = factor_br * 12.0
    glow_br_b = factor_br * 15.0
    
    final_r = np.clip(base_r + glow_tl_r + glow_br_r, 0, 255).astype(np.uint8)
    final_g = np.clip(base_g + glow_tl_g + glow_br_g, 0, 255).astype(np.uint8)
    final_b = np.clip(base_b + glow_tl_b + glow_br_b, 0, 255).astype(np.uint8)
    final_a = np.full((H2, W2), 255, dtype=np.uint8)
    
    rgba_array = np.dstack((final_r, final_g, final_b, final_a))
    canvas = Image.fromarray(rgba_array)
    draw = ImageDraw.Draw(canvas)

    # Subtle framing border
    draw.rounded_rectangle([(0, 0), (W2 - 1, H2 - 1)], radius=0, outline=(34, 40, 48, 255), width=2)

    # 2. Typography Fonts (at 2x)
    font_brand = get_font_2x(88, bold=True)
    font_badge = get_font_2x(26, bold=True)
    font_subbrand = get_font_2x(36, bold=True)
    font_headline = get_font_2x(54, bold=True)
    font_body = get_font_2x(32, bold=False)
    font_pill = get_font_2x(26, bold=True)
    font_footer = get_font_2x(24, bold=False)

    # 3. Sotto App Icon (at 2x)
    icon_x, icon_y = 128, 140
    icon_size = 184
    if os.path.exists(icon_path):
        icon_src = Image.open(icon_path).convert("RGBA")
        icon_resized = icon_src.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
        
        # Apple Squircle mask (radius ~ 22.5%)
        icon_mask = Image.new("L", (icon_size, icon_size), 0)
        im_draw = ImageDraw.Draw(icon_mask)
        im_draw.rounded_rectangle([(0, 0), (icon_size, icon_size)], radius=42, fill=255)
        
        # Multi-layer drop shadow on full canvas
        icon_shadow_layer = Image.new("RGBA", (W2, H2), (0, 0, 0, 0))
        is_draw = ImageDraw.Draw(icon_shadow_layer)
        is_draw.rounded_rectangle([(icon_x, icon_y + 10), (icon_x + icon_size, icon_y + 10 + icon_size)],
                                 radius=42, fill=(0, 0, 0, 160))
        canvas.alpha_composite(icon_shadow_layer.filter(ImageFilter.GaussianBlur(18)))
        
        # Paste app icon + crisp outer ring
        canvas.paste(icon_resized, (icon_x, icon_y), icon_mask)
        draw.rounded_rectangle([(icon_x, icon_y), (icon_x + icon_size, icon_y + icon_size)],
                               radius=42, outline=(255, 255, 255, 36), width=2)

    # 4. Brand Title & Platform Badge
    text_x = icon_x + icon_size + 32
    brand_text = "Sotto"
    draw.text((text_x, 156), brand_text, font=font_brand, fill=(255, 255, 255, 255))
    
    brand_bbox = font_brand.getbbox(brand_text)
    brand_w = brand_bbox[2] - brand_bbox[0]
    
    # "iOS" pill badge
    badge_x = text_x + brand_w + 24
    badge_y = 172
    badge_w, badge_h = 96, 48
    draw.rounded_rectangle([(badge_x, badge_y), (badge_x + badge_w, badge_y + badge_h)],
                           radius=24, fill=(30, 42, 35, 240), outline=(142, 178, 146, 220), width=2)
    draw.text((badge_x + 22, badge_y + 8), "iOS", font=font_badge, fill=(162, 210, 172, 255))

    # Subtitle / Category
    draw.text((text_x, 268), "Calm Crisis Navigation & Assistive AAC", font=font_subbrand, fill=(142, 178, 146, 255))

    # 5. Core Value Headline
    headline_text = "Calm yes/no connection during\nmeltdowns & verbal shutdowns."
    draw.text((128, 404), headline_text, font=font_headline, fill=(245, 247, 250, 255), spacing=12)

    # 6. Supporting Audience & Purpose
    body_text = (
        "A gentle binary triage HUD for caregivers & families, paired\n"
        "with a dignified, low-stimulation AAC speech board."
    )
    draw.text((128, 564), body_text, font=font_body, fill=(168, 178, 188, 255), spacing=10)

    # 7. Feature Badges (Organized in 2 dignified rows)
    row1 = [
        ("partner", "Caregiver Two-Way HUD", (129, 199, 132)),
        ("tree", "Guided Crisis Tree", (255, 183, 77)),
        ("lock", "100% Offline & Private", (144, 202, 249)),
    ]
    row2 = [
        ("bolt", "Action Button & Siri", (186, 104, 200)),
        ("swift", "100% Native SwiftUI", (255, 138, 101)),
        ("shield", "Zero 3rd-Party Libs", (207, 216, 220)),
    ]

    for r_idx, pills in enumerate([row1, row2]):
        pill_x = 128
        pill_y = 736 + (r_idx * 96)
        for icon_type, label_txt, icon_color in pills:
            bbox = font_pill.getbbox(label_txt)
            txt_w = bbox[2] - bbox[0]
            pw = txt_w + 96
            ph = 72
            draw.rounded_rectangle(
                [(pill_x, pill_y), (pill_x + pw, pill_y + ph)],
                radius=36,
                fill=(26, 32, 38, 230),
                outline=(54, 64, 76, 240),
                width=2
            )
            draw_badge_icon_2x(draw, icon_type, pill_x + 26, pill_y + 22, icon_color)
            draw.text((pill_x + 68, pill_y + 18), label_txt, font=font_pill, fill=(225, 232, 240, 255))
            pill_x += pw + 24

    # 8. Bottom Tagline / Accessibility guarantee
    footer_text = "Designed for autistic teens & adults, caregivers, and non-speaking individuals • WCAG AAA"
    draw.text((128, 1148), footer_text, font=font_footer, fill=(112, 124, 136, 255))

    # 9. Realistic iPhone 16 Pro Mockup on Right
    if os.path.exists(screenshot_path):
        screen_img = Image.open(screenshot_path).convert("RGBA")
        
        # Dimensions for iPhone mockup at 2x
        mock_w = 520
        mock_h = int(mock_w * (2622 / 1206)) # ~1130 px
        screen_resized = screen_img.resize((mock_w, mock_h), Image.Resampling.LANCZOS)

        bezel = 14
        pw = mock_w + bezel * 2
        ph = mock_h + bezel * 2
        r = 76 # Rounded corner radius

        phone_x = 1840
        phone_y = (H2 - ph) // 2

        # Step 9a: Render seamless full-canvas drop shadows (prevents any box clipping)
        shadow_layer = Image.new("RGBA", (W2, H2), (0, 0, 0, 0))
        sdraw = ImageDraw.Draw(shadow_layer)
        # Deep directional contact shadow
        sdraw.rounded_rectangle([phone_x, phone_y + 24, phone_x + pw, phone_y + 24 + ph],
                                radius=r, fill=(0, 0, 0, 160))
        # Soft ambient shadow
        sdraw.rounded_rectangle([phone_x, phone_y + 10, phone_x + pw, phone_y + 10 + ph],
                                radius=r, fill=(0, 0, 0, 120))
        canvas.alpha_composite(shadow_layer.filter(ImageFilter.GaussianBlur(38)))

        # Re-bind draw context after alpha_composite
        draw = ImageDraw.Draw(canvas)

        # Step 9b: Titanium Enclosure (Natural / Graphite Titanium)
        draw.rounded_rectangle(
            [phone_x, phone_y, phone_x + pw, phone_y + ph],
            radius=r,
            fill=(26, 30, 36, 255),
            outline=(68, 78, 92, 255),
            width=3
        )

        # Specular Chamfer highlight
        draw.rounded_rectangle(
            [phone_x + 2, phone_y + 2, phone_x + pw - 2, phone_y + ph - 2],
            radius=r - 2,
            outline=(104, 118, 134, 120),
            width=2
        )

        # Step 9c: Screen mask & paste screen
        scr_mask = Image.new("L", (mock_w, mock_h), 0)
        smdraw = ImageDraw.Draw(scr_mask)
        smdraw.rounded_rectangle([(0, 0), (mock_w, mock_h)], radius=r - bezel - 4, fill=255)
        
        screen_x = phone_x + bezel
        screen_y = phone_y + bezel
        canvas.paste(screen_resized, (screen_x, screen_y), scr_mask)

        # Step 9d: Authentic Dynamic Island
        di_w = 124
        di_h = 34
        di_x = screen_x + (mock_w - di_w) // 2
        di_y = screen_y + 14
        draw.rounded_rectangle([(di_x, di_y), (di_x + di_w, di_y + di_h)], radius=17, fill=(0, 0, 0, 255))
        # Camera sensor reflection
        draw.ellipse([di_x + di_w - 28, di_y + 8, di_x + di_w - 14, di_y + 22], fill=(14, 18, 24, 255))

    # 10. Save Master @2x Retina Asset (Flatten to RGB)
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    retina_path = output_path.replace(".png", "@2x.png")
    canvas_rgb = canvas.convert("RGB")
    canvas_rgb.save(retina_path, "PNG", optimize=True)
    print(f"Saved master Retina 2x banner: {retina_path} ({W2}x{H2})")

    # 11. Downsample with Lanczos to Standard 1x (1280x640)
    canvas_1x = canvas_rgb.resize((1280, 640), Image.Resampling.LANCZOS)
    canvas_1x.save(output_path, "PNG", optimize=True)
    print(f"Saved super-sampled standard banner: {output_path} (1280x640)")

if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "assets/sotto_ios_banner.png"
    generate_header_asset(output_path=out)
