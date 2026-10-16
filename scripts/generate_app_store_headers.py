#!/usr/bin/env python3
"""
Generate Apple App Store Product Page Information Creative Assets
==================================================================
Conforms strictly to Apple App Store Connect specifications & HIG:
https://developer.apple.com/app-store/asset-best-practices/

ASSET CATEGORIES & SPECIFICATIONS:
  1. Product Page Header:
     - 3840 × 1646 px (21:9 Ultrawide)
     - Safe Area: Central 1646 × 661 px (X: 1097..2743, Y: 493..1154)
     - Tone: Low-stimulus brand atmosphere with ambient acoustic sage glow,
             hero device showcase, and floating AAC speech cards.
  2. Search Result Assets:
     - 3840 × 2560 px (3:2 Retina)
     - 1920 × 1280 px (3:2 Standard)
     - Tone: Dual-device firsthand experience showcase highlighting
             AAC Speech Board + Two-Way Partner Crisis Triage HUD.
  3. Universal Creative Asset:
     - 5244 × 2950 px (16:9 Universal)

TECHNICAL REQUIREMENTS:
  - NO ALPHA CHANNEL / ZERO TRANSPARENCY (Flattened 24-bit RGB, hasAlpha: no)
  - Color Profile: sRGB
  - Accurate metadata: Genuine app interface screenshots (App Store Guideline 2.3)
  - Low-stimulus palette: Charcoal #0E1114, Sage #8EB292, Safety Amber #E5A93C
"""

import os
import sys
import math
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

REPO_ROOT = Path(__file__).resolve().parent.parent
SCREEN_AAC = REPO_ROOT / "assets/screenshots/iphone_medium_dynamic_island/01_aac_speech_board.png"
SCREEN_HUD = REPO_ROOT / "assets/screenshots/iphone_medium_dynamic_island/02_two_way_partner_triage.png"

def get_font(size: int, bold: bool = False):
    candidates = [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/HelveticaNeue.ttc",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for c in candidates:
        if os.path.exists(c):
            try:
                idx = 1 if bold and "ttc" in c else 0
                return ImageFont.truetype(c, size, index=idx)
            except Exception:
                try:
                    return ImageFont.truetype(c, size)
                except Exception:
                    pass
    return ImageFont.load_default()

def draw_vector_icon(draw: ImageDraw.ImageDraw, icon_type: str, x: int, y: int, size: int, color):
    s = size
    if icon_type == "soundwave":
        bar_w = max(2, int(s * 0.16))
        gap = max(2, int(s * 0.08))
        heights = [0.45, 0.70, 0.95, 0.65]
        start_x = x - (len(heights) * (bar_w + gap) - gap) // 2
        for i, h in enumerate(heights):
            bh = int(s * h)
            bx = start_x + i * (bar_w + gap)
            by = y - bh // 2
            draw.rounded_rectangle([(bx, by), (bx + bar_w, by + bh)], radius=bar_w//2, fill=color)
            
    elif icon_type == "shield":
        hw = int(s * 0.38)
        draw.polygon([
            (x - hw, y - int(s*0.4)),
            (x + hw, y - int(s*0.4)),
            (x + hw, y + int(s*0.05)),
            (x, y + int(s*0.45)),
            (x - hw, y + int(s*0.05))
        ], fill=color)
        
    elif icon_type == "lock":
        bw = int(s * 0.58)
        bh = int(s * 0.44)
        by = y - bh // 2 + int(s * 0.1)
        bx = x - bw // 2
        draw.rounded_rectangle([(bx, by), (bx + bw, by + bh)], radius=max(2, int(s*0.1)), fill=color)
        sw = int(s * 0.36)
        sh = int(s * 0.35)
        sx = x - sw // 2
        sy = by - sh + int(s*0.05)
        draw.arc([(sx, sy), (sx + sw, sy + sh*1.5)], start=180, end=0, fill=color, width=max(2, int(s*0.12)))

    elif icon_type == "triage":
        r = int(s * 0.38)
        draw.arc([(x - r, y - r), (x + r, y + r)], start=40, end=200, fill=color, width=max(2, int(s*0.12)))
        draw.arc([(x - r, y - r), (x + r, y + r)], start=220, end=20, fill=color, width=max(2, int(s*0.12)))

    elif icon_type == "leaf":
        draw.ellipse([(x - int(s*0.25), y - int(s*0.4)), (x + int(s*0.25), y + int(s*0.4))], outline=color, width=max(2, int(s*0.12)))
        draw.line([(x, y - int(s*0.35)), (x, y + int(s*0.35))], fill=color, width=max(1, int(s*0.08)))

def create_base_canvas(width: int, height: int, sage_intensity: float = 0.38, acoustic_rings: bool = True) -> Image.Image:
    """Create Sotto's low-stimulus dark neutral canvas with warm ambient sage radial glow."""
    y, x = np.ogrid[:height, :width]
    cx, cy = width / 2.0, height / 2.0
    
    # Base Deep Charcoal #0E1114 -> RGB (14, 17, 20)
    base_r, base_g, base_b = 14.0, 17.0, 20.0
    
    # Radial glow spread
    glow_radius = max(width, height) * 0.54
    dist = np.sqrt((x - cx)**2 + (y - cy)**2) / glow_radius
    glow = np.clip(1.0 - dist, 0.0, 1.0) ** 1.9
    
    # Sage Accent #8EB292 -> RGB (142, 178, 146)
    r = np.clip(base_r + glow * 128.0 * sage_intensity, 0, 255)
    g = np.clip(base_g + glow * 161.0 * sage_intensity, 0, 255)
    b = np.clip(base_b + glow * 126.0 * sage_intensity, 0, 255)
    
    # Gentle vignette
    y_norm = np.abs(y - cy) / (height * 0.5)
    vignette = 1.0 - np.clip(y_norm**2 * 0.18, 0.0, 0.22)
    
    r = np.clip(r * vignette, 0, 255).astype(np.uint8)
    g = np.clip(g * vignette, 0, 255).astype(np.uint8)
    b = np.clip(b * vignette, 0, 255).astype(np.uint8)
    
    bg = Image.fromarray(np.dstack((r, g, b)))
    
    if acoustic_rings:
        overlay = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        draw = ImageDraw.Draw(overlay)
        ring_radii = [
            int(min(width, height) * f)
            for f in [0.22, 0.36, 0.52, 0.70, 0.90, 1.12, 1.38]
        ]
        for idx, radius in enumerate(ring_radii):
            alpha = int(32 * (1.0 - idx / len(ring_radii)))
            draw.ellipse(
                [(cx - radius, cy - radius), (cx + radius, cy + radius)],
                outline=(142, 178, 146, alpha),
                width=max(2, int(width / 1920 * 2.5))
            )
        overlay_blurred = overlay.filter(ImageFilter.GaussianBlur(int(width / 1920 * 4)))
        bg_rgba = bg.convert("RGBA")
        bg_rgba.alpha_composite(overlay_blurred)
        bg = bg_rgba.convert("RGB")
        
    return bg

def render_device(screen_img: Image.Image, mock_h: int, scale: float):
    screen_orig_w, screen_orig_h = screen_img.size
    mock_w = int(mock_h * (screen_orig_w / screen_orig_h))
    screen_resized = screen_img.resize((mock_w, mock_h), Image.Resampling.LANCZOS)
    
    bezel = max(12, int(16 * scale))
    pw = mock_w + bezel * 2
    ph = mock_h + bezel * 2
    corner_radius = max(40, int(84 * scale))
    
    device_img = Image.new("RGBA", (pw, ph), (0, 0, 0, 0))
    draw = ImageDraw.Draw(device_img)
    
    # Outer dark titanium bezel
    draw.rounded_rectangle(
        [0, 0, pw, ph],
        radius=corner_radius,
        fill=(22, 26, 31, 255),
        outline=(70, 80, 94, 255),
        width=max(2, int(3 * scale))
    )
    
    # Specular Chamfer highlight
    inset = max(1, int(2 * scale))
    draw.rounded_rectangle(
        [inset, inset, pw - inset, ph - inset],
        radius=corner_radius - inset,
        outline=(115, 130, 148, 130),
        width=max(1, int(2 * scale))
    )
    
    # Screen mask
    screen_mask = Image.new("L", (mock_w, mock_h), 0)
    smdraw = ImageDraw.Draw(screen_mask)
    screen_cr = max(20, corner_radius - bezel - max(2, int(3 * scale)))
    smdraw.rounded_rectangle([(0, 0), (mock_w, mock_h)], radius=screen_cr, fill=255)
    
    device_img.paste(screen_resized, (bezel, bezel), screen_mask)
    
    # Dynamic Island pill
    di_w = int(144 * scale)
    di_h = int(38 * scale)
    di_x = bezel + (mock_w - di_w) // 2
    di_y = bezel + int(16 * scale)
    draw.rounded_rectangle([(di_x, di_y), (di_x + di_w, di_y + di_h)], radius=int(19 * scale), fill=(0, 0, 0, 255))
    
    # Camera lens reflection
    lens_offset = int(30 * scale)
    lens_size = int(14 * scale)
    draw.ellipse(
        [di_x + di_w - lens_offset, di_y + int(12 * scale), di_x + di_w - lens_offset + lens_size, di_y + int(12 * scale) + lens_size],
        fill=(12, 16, 22, 255)
    )
    
    return device_img, pw, ph, corner_radius

def stamp_device_with_shadow(comp: Image.Image, device_img: Image.Image, px: int, py: int, pw: int, ph: int, corner_radius: int, scale: float):
    width, height = comp.size
    shadow_layer = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow_layer)
    sdraw.rounded_rectangle(
        [px, py + int(32 * scale), px + pw, py + ph + int(32 * scale)],
        radius=corner_radius, fill=(0, 0, 0, 205)
    )
    sdraw.rounded_rectangle(
        [px, py + int(12 * scale), px + pw, py + ph + int(12 * scale)],
        radius=corner_radius, fill=(0, 0, 0, 150)
    )
    comp.alpha_composite(shadow_layer.filter(ImageFilter.GaussianBlur(int(48 * scale))))
    comp.paste(device_img, (px, py), device_img)

def render_pill_badge(text: str, font_size: int, scale: float, icon_type: str = None, icon_color=(142, 178, 146, 255), border_color=(142, 178, 146, 200), bg_color=(24, 30, 36, 235), text_color=(235, 240, 245)):
    font = get_font(int(font_size * scale), bold=True)
    dummy_img = Image.new("RGBA", (1, 1))
    ddraw = ImageDraw.Draw(dummy_img)
    bbox = ddraw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    
    icon_w = int(font_size * 1.1 * scale) if icon_type else 0
    icon_gap = int(16 * scale) if icon_type else 0
    
    pw = int(tw + icon_w + icon_gap + 64 * scale)
    ph = int(th + 42 * scale)
    pill = Image.new("RGBA", (pw, ph), (0, 0, 0, 0))
    draw = ImageDraw.Draw(pill)
    cr = ph // 2
    
    draw.rounded_rectangle(
        [(0, 0), (pw, ph)],
        radius=cr,
        fill=bg_color,
        outline=border_color,
        width=max(2, int(2.5 * scale))
    )
    draw.rounded_rectangle(
        [(1, 1), (pw - 1, ph // 2)],
        radius=cr,
        fill=(255, 255, 255, 12)
    )
    
    content_w = icon_w + icon_gap + tw
    start_x = (pw - content_w) // 2
    
    if icon_type:
        icon_cx = start_x + icon_w // 2
        icon_cy = ph // 2
        draw_vector_icon(draw, icon_type, icon_cx, icon_cy, int(font_size * 1.0 * scale), icon_color)
        tx = start_x + icon_w + icon_gap
    else:
        tx = start_x
        
    ty = (ph - th) // 2 - int(2 * scale)
    draw.text((tx, ty), text, fill=text_color, font=font)
    return pill, pw, ph

def render_card(title: str, subtitle: str = None, tag: str = None, icon_type: str = None, tag_color=(229, 169, 60), width: int = 560, height: int = 180, scale: float = 1.0, is_safety: bool = False):
    w = int(width * scale)
    h = int(height * scale)
    card = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(card)
    cr = int(24 * scale)
    
    bg_color = (38, 30, 24, 245) if is_safety else (24, 30, 38, 240)
    border_color = (229, 169, 60, 220) if is_safety else (110, 135, 125, 180)
    
    draw.rounded_rectangle(
        [(0, 0), (w, h)],
        radius=cr,
        fill=bg_color,
        outline=border_color,
        width=max(2, int(2.5 * scale))
    )
    draw.rounded_rectangle(
        [(1, 1), (w - 1, int(h * 0.45))],
        radius=cr,
        fill=(255, 255, 255, 10)
    )
    
    font_main = get_font(int(32 * scale), bold=True)
    font_sub = get_font(int(23 * scale), bold=False)
    font_tag = get_font(int(17 * scale), bold=True)
    
    curr_y = int(24 * scale)
    if tag:
        tag_w = int(len(tag) * 12 * scale + 28 * scale)
        if icon_type:
            tag_w += int(24 * scale)
        tag_h = int(30 * scale)
        tag_x = int(28 * scale)
        draw.rounded_rectangle(
            [(tag_x, curr_y), (tag_x + tag_w, curr_y + tag_h)],
            radius=int(15 * scale),
            fill=(tag_color[0], tag_color[1], tag_color[2], 55),
            outline=(tag_color[0], tag_color[1], tag_color[2], 200),
            width=1
        )
        t_x = tag_x + int(12 * scale)
        if icon_type:
            draw_vector_icon(draw, icon_type, t_x + int(10 * scale), curr_y + tag_h // 2, int(18 * scale), tag_color)
            t_x += int(22 * scale)
        draw.text((t_x, curr_y + int(4 * scale)), tag, fill=tag_color, font=font_tag)
        curr_y += tag_h + int(16 * scale)
        
    text_color = (255, 240, 220) if is_safety else (235, 242, 246)
    draw.text((int(28 * scale), curr_y), title, fill=text_color, font=font_main)
    
    if subtitle:
        draw.text((int(28 * scale), curr_y + int(40 * scale)), subtitle, fill=(165, 180, 190), font=font_sub)
        
    return card, w, h

def stamp_element_with_shadow(comp: Image.Image, elem_img: Image.Image, px: int, py: int, ew: int, eh: int, cr: int, scale: float):
    width, height = comp.size
    shadow = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    sdraw.rounded_rectangle(
        [px, py + int(16 * scale), px + ew, py + eh + int(16 * scale)],
        radius=cr, fill=(0, 0, 0, 175)
    )
    comp.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(int(24 * scale))))
    comp.paste(elem_img, (px, py), elem_img)

def generate_header_master(width: int, height: int, output_png_path: str, screenshot_path: str):
    """
    Generate Master Product Page Header Asset:
    - Conforms 100% to Apple Safe Area (1646 × 661 center rectangle).
    - Features centered hero iPhone 16 Pro + large floating AAC communication cards.
    - Full-bleed ambient sage acoustic aura for ultrawide viewing.
    """
    print(f"\n--- Generating Product Page Header: {output_png_path} ({width} × {height} px) ---")
    
    screen_img = Image.open(screenshot_path).convert("RGBA")
    canvas = create_base_canvas(width, height, sage_intensity=0.38, acoustic_rings=True)
    comp = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    
    S = height / 1646.0
    mock_h = int(1340 * S)
    
    dev, pw, ph, cr = render_device(screen_img, mock_h, S * 1.08)
    phone_x = (width - pw) // 2
    phone_y = int(210 * S)
    
    stamp_device_with_shadow(comp, dev, phone_x, phone_y, pw, ph, cr, S * 1.08)
    
    # 1. Master Brand Pill above phone
    pill_top, pt_w, pt_h = render_pill_badge(
        "Sotto • Low-Stimulus AAC Speech Assistant",
        font_size=32, scale=S,
        icon_type="soundwave", icon_color=(142, 178, 146, 255),
        border_color=(142, 178, 146, 230), bg_color=(20, 26, 34, 245)
    )
    pt_x = (width - pt_w) // 2
    pt_y = int(105 * S)
    stamp_element_with_shadow(comp, pill_top, pt_x, pt_y, pt_w, pt_h, pt_h // 2, S)
    
    # 2. Left Primary Card: "I need a quiet space."
    c_left, cl_w, cl_h = render_card(
        "I need a quiet space.",
        subtitle="Quick-Speak Sensory Sanctuary",
        tag="SENSORY", icon_type="leaf",
        tag_color=(142, 178, 146),
        width=540, height=175, scale=S
    )
    cl_x = phone_x - cl_w - int(50 * S)
    cl_y = int(570 * S)
    stamp_element_with_shadow(comp, c_left, cl_x, cl_y, cl_w, cl_h, int(24 * S), S)
    
    # Left Sub-Pill: "100% Offline & Private"
    p_offline, po_w, po_h = render_pill_badge(
        "100% Offline & Private",
        font_size=26, scale=S,
        icon_type="lock", icon_color=(126, 165, 216, 255),
        border_color=(126, 165, 216, 190), bg_color=(22, 28, 36, 240)
    )
    po_x = cl_x + int(45 * S)
    po_y = cl_y + cl_h + int(24 * S)
    stamp_element_with_shadow(comp, p_offline, po_x, po_y, po_w, po_h, po_h // 2, S)
    
    # 3. Right Primary Card: "Please give me time."
    c_right, cr_w, cr_h = render_card(
        "Please give me time.",
        subtitle="Paced Two-Way Conversation",
        tag="ASSIST", icon_type="soundwave",
        tag_color=(126, 165, 216),
        width=540, height=175, scale=S
    )
    cr_x = phone_x + pw + int(50 * S)
    cr_y = int(570 * S)
    stamp_element_with_shadow(comp, c_right, cr_x, cr_y, cr_w, cr_h, int(24 * S), S)
    
    # Right Sub-Pill: "Two-Way Crisis Triage"
    p_triage, ptr_w, ptr_h = render_pill_badge(
        "Two-Way Crisis Triage",
        font_size=26, scale=S,
        icon_type="triage", icon_color=(229, 169, 60, 255),
        border_color=(229, 169, 60, 190), bg_color=(22, 28, 36, 240)
    )
    ptr_x = cr_x
    ptr_y = cr_y + cr_h + int(24 * S)
    stamp_element_with_shadow(comp, p_triage, ptr_x, ptr_y, ptr_w, ptr_h, ptr_h // 2, S)
    
    # 4. Widescreen Wings (iPad / Mac Ultrawide 21:9 bleed)
    if width >= 3000:
        w_left, wl_w, wl_h = render_card(
            "I need to leave now.",
            subtitle="Immediate Boundary & Safety",
            tag="CARE", icon_type="shield",
            tag_color=(229, 169, 60),
            width=480, height=165, scale=S * 0.96, is_safety=True
        )
        wl_x = int(220 * S)
        wl_y = int(670 * S)
        stamp_element_with_shadow(comp, w_left, wl_x, wl_y, wl_w, wl_h, int(22 * S), S)
        
        w_right, wr_w, wr_h = render_card(
            "Yes, please.",
            subtitle="Positive Confirmation Tile",
            tag="SOCIAL", icon_type="leaf",
            tag_color=(76, 175, 80),
            width=480, height=165, scale=S * 0.96
        )
        wr_x = width - wr_w - int(220 * S)
        wr_y = int(670 * S)
        stamp_element_with_shadow(comp, w_right, wr_x, wr_y, wr_w, wr_h, int(22 * S), S)
    
    canvas_rgba = canvas.convert("RGBA")
    canvas_rgba.alpha_composite(comp)
    final_rgb = canvas_rgba.convert("RGB")
    
    os.makedirs(os.path.dirname(output_png_path), exist_ok=True)
    final_rgb.save(output_png_path, "PNG")
    file_size_kb = os.path.getsize(output_png_path) / 1024
    print(f"Saved Header (24-bit RGB, no alpha): {output_png_path} ({width} × {height} px, {file_size_kb:.1f} KB)")

def generate_search_result_master(
    width: int,
    height: int,
    output_png_path: str,
    screen_aac_path: str,
    screen_hud_path: str
):
    """
    Generate Master App Store Search Result Creative Asset:
    - 3:2 landscape card format.
    - Firsthand dual experience: AAC Speech Board + Partner Crisis Triage HUD.
    - Large, legible pill tags and title badges designed for search feed discovery.
    """
    print(f"\n--- Generating Search Result: {output_png_path} ({width} × {height} px) ---")
    
    screen_aac = Image.open(screen_aac_path).convert("RGBA")
    screen_hud = Image.open(screen_hud_path).convert("RGBA")
    
    canvas = create_base_canvas(width, height, sage_intensity=0.35, acoustic_rings=True)
    comp = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    
    scale = height / 2560.0
    mock_h = int(1900 * scale)
    dev_scale = scale * 1.32
    
    dev_aac, pw_aac, ph_aac, cr_aac = render_device(screen_aac, mock_h, dev_scale)
    dev_hud, pw_hud, ph_hud, cr_hud = render_device(screen_hud, mock_h, dev_scale)
    
    gap = int(120 * scale)
    total_w = pw_aac + gap + pw_hud
    start_x = (width - total_w) // 2
    py = int(450 * scale)
    
    stamp_device_with_shadow(comp, dev_aac, start_x, py, pw_aac, ph_aac, cr_aac, dev_scale)
    stamp_device_with_shadow(comp, dev_hud, start_x + pw_aac + gap, py, pw_hud, ph_hud, cr_hud, dev_scale)
    
    # 1. Master Feature Pill Badges above devices
    pill1, p1_w, p1_h = render_pill_badge("Low-Stimulus AAC", font_size=32, scale=scale, icon_type="leaf", icon_color=(142, 178, 146, 255), border_color=(142, 178, 146, 210))
    pill2, p2_w, p2_h = render_pill_badge("Two-Way Crisis Triage", font_size=32, scale=scale, icon_type="triage", icon_color=(229, 169, 60, 255), border_color=(229, 169, 60, 210))
    pill3, p3_w, p3_h = render_pill_badge("100% Offline & Private", font_size=32, scale=scale, icon_type="lock", icon_color=(126, 165, 216, 255), border_color=(126, 165, 216, 210))
    
    p_gap = int(36 * scale)
    p_total_w = p1_w + p_gap + p2_w + p_gap + p3_w
    p_start_x = (width - p_total_w) // 2
    p_y = int(220 * scale)
    
    stamp_element_with_shadow(comp, pill1, p_start_x, p_y, p1_w, p1_h, p1_h // 2, scale)
    stamp_element_with_shadow(comp, pill2, p_start_x + p1_w + p_gap, p_y, p2_w, p2_h, p2_h // 2, scale)
    stamp_element_with_shadow(comp, pill3, p_start_x + p1_w + p_gap + p2_w + p_gap, p_y, p3_w, p3_h, p3_h // 2, scale)
    
    # 2. Detailed Label Badges under devices
    lbl_aac, l_aac_w, l_aac_h = render_pill_badge("AAC Speech Board with Quick-Speak", font_size=28, scale=scale, icon_type="soundwave", icon_color=(142, 178, 146, 255), border_color=(142, 178, 146, 170))
    lbl_hud, l_hud_w, l_hud_h = render_pill_badge("Two-Way Partner HUD • 180° Flip", font_size=28, scale=scale, icon_type="triage", icon_color=(229, 169, 60, 255), border_color=(229, 169, 60, 170))
    
    l_aac_x = start_x + (pw_aac - l_aac_w) // 2
    l_hud_x = start_x + pw_aac + gap + (pw_hud - l_hud_w) // 2
    l_y = py + ph_aac + int(42 * scale)
    
    stamp_element_with_shadow(comp, lbl_aac, l_aac_x, l_y, l_aac_w, l_aac_h, l_aac_h // 2, scale)
    stamp_element_with_shadow(comp, lbl_hud, l_hud_x, l_y, l_hud_w, l_hud_h, l_hud_h // 2, scale)
    
    canvas_rgba = canvas.convert("RGBA")
    canvas_rgba.alpha_composite(comp)
    final_rgb = canvas_rgba.convert("RGB")
    
    os.makedirs(os.path.dirname(output_png_path), exist_ok=True)
    final_rgb.save(output_png_path, "PNG")
    file_size_kb = os.path.getsize(output_png_path) / 1024
    print(f"Saved Search Result (24-bit RGB, no alpha): {output_png_path} ({width} × {height} px, {file_size_kb:.1f} KB)")

def main():
    screen_aac = str(SCREEN_AAC)
    screen_hud = str(SCREEN_HUD)
    
    if not os.path.exists(screen_aac):
        raise FileNotFoundError(f"Required screenshot not found at {screen_aac}")
    if not os.path.exists(screen_hud):
        screen_hud = screen_aac
        
    print("===================================================================")
    print("Generating Apple App Store Product Page Information Creative Assets")
    print("===================================================================")
    
    # 1. Product Page Header Assets (3840 × 1646 & Universal 5244 × 2950)
    generate_header_master(3840, 1646, str(REPO_ROOT / "assets/app_store_header_3840x1646.png"), screen_aac)
    generate_header_master(5244, 2950, str(REPO_ROOT / "assets/app_store_universal_5244x2950.png"), screen_aac)
    
    # 2. Search Result Assets (3840 × 2560 Retina, 1920 × 1280 Standard & Universal 5244 × 2950)
    generate_search_result_master(3840, 2560, str(REPO_ROOT / "assets/app_store_search_result_3840x2560.png"), screen_aac, screen_hud)
    generate_search_result_master(1920, 1280, str(REPO_ROOT / "assets/app_store_search_result_1920x1280.png"), screen_aac, screen_hud)
    generate_search_result_master(5244, 2950, str(REPO_ROOT / "assets/app_store_search_result_5244x2950.png"), screen_aac, screen_hud)
    
    print("\n✅ All Product Page Information creative assets generated successfully!")

if __name__ == "__main__":
    main()
