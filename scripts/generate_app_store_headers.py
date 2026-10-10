#!/usr/bin/env python3
"""
Generate Apple App Store Product Page Information Creative Assets
==================================================================
Conforms strictly to Apple App Store Connect specifications:
https://developer.apple.com/app-store/asset-best-practices/

ASSET CATEGORIES & SUPPORTED SIZES:
  1. Product Page Header:
     - 3840 × 1646 px (Dedicated 21:9 ultrawide header)
     - 5244 × 2950 px (Universal 16:9 creative asset)
  2. Search Result Asset:
     - 3840 × 2560 px (Dedicated 3:2 high-resolution)
     - 1920 × 1280 px (Dedicated 3:2 standard resolution)
     - 5244 × 2950 px (Universal 16:9 creative asset)

CRITICAL APP STORE CONNECT TECHNICAL REQUIREMENTS:
  - NO ALPHA CHANNEL / NO TRANSPARENCY (Flattened 24-bit RGB, hasAlpha: no)
  - Color Profile: sRGB
  - Safe Area Compliance: All key focal elements centered within safe zones
  - Clean hero layout: Pure app interface showcase without marketing copy clutter
  - Output format: PNG only (24-bit RGB)
"""

import os
import sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

def create_base_canvas(width: int, height: int, glow_spread: float = 0.48) -> Image.Image:
    """Create Sotto's low-stimulus dark neutral canvas with ambient sage radial glow."""
    y_coords, x_coords = np.ogrid[:height, :width]
    
    # Deep calming charcoal #0E1114 -> RGB (14, 17, 20)
    base_r, base_g, base_b = 14.0, 17.0, 20.0
    
    # Sage Ambient Radial Glow centered behind devices
    center_x, center_y = width / 2.0, height / 2.0
    dist_center = np.sqrt((x_coords - center_x) ** 2 + (y_coords - center_y) ** 2) / (width * glow_spread)
    factor_glow = np.clip(1.0 - dist_center, 0.0, 1.0) ** 1.8
    glow_r = factor_glow * 20.0
    glow_g = factor_glow * 32.0
    glow_b = factor_glow * 24.0
    
    final_r = np.clip(base_r + glow_r, 0, 255).astype(np.uint8)
    final_g = np.clip(base_g + glow_g, 0, 255).astype(np.uint8)
    final_b = np.clip(base_b + glow_b, 0, 255).astype(np.uint8)
    
    return Image.fromarray(np.dstack((final_r, final_g, final_b)))

def render_device(screen_img: Image.Image, mock_h: int, scale: float):
    """Render an authentic iPhone 16 Pro enclosure with Dynamic Island."""
    screen_orig_w, screen_orig_h = screen_img.size
    mock_w = int(mock_h * (screen_orig_w / screen_orig_h))
    screen_resized = screen_img.resize((mock_w, mock_h), Image.Resampling.LANCZOS)
    
    bezel = max(12, int(16 * scale))
    pw = mock_w + bezel * 2
    ph = mock_h + bezel * 2
    corner_radius = max(40, int(88 * scale))
    
    device_img = Image.new("RGBA", (pw, ph), (0, 0, 0, 0))
    draw = ImageDraw.Draw(device_img)
    
    # Titanium frame (Dark Slate frame)
    draw.rounded_rectangle(
        [0, 0, pw, ph],
        radius=corner_radius,
        fill=(26, 30, 36, 255),
        outline=(72, 82, 96, 255),
        width=max(2, int(3 * scale))
    )
    
    # Specular Chamfer highlight
    inset = max(2, int(2 * scale))
    draw.rounded_rectangle(
        [inset, inset, pw - inset, ph - inset],
        radius=corner_radius - inset,
        outline=(100, 114, 130, 120),
        width=max(1, int(2 * scale))
    )
    
    # Screen mask with matching curvature
    screen_mask = Image.new("L", (mock_w, mock_h), 0)
    smdraw = ImageDraw.Draw(screen_mask)
    screen_corner_radius = max(20, corner_radius - bezel - max(2, int(4 * scale)))
    smdraw.rounded_rectangle([(0, 0), (mock_w, mock_h)], radius=screen_corner_radius, fill=255)
    
    device_img.paste(screen_resized, (bezel, bezel), screen_mask)
    
    # Dynamic Island pill
    di_w = int(150 * scale)
    di_h = int(42 * scale)
    di_x = bezel + (mock_w - di_w) // 2
    di_y = bezel + int(18 * scale)
    draw.rounded_rectangle([(di_x, di_y), (di_x + di_w, di_y + di_h)], radius=int(21 * scale), fill=(0, 0, 0, 255))
    
    # Front camera lens reflection
    lens_offset = int(34 * scale)
    lens_size = int(16 * scale)
    draw.ellipse(
        [di_x + di_w - lens_offset, di_y + int(13 * scale), di_x + di_w - lens_offset + lens_size, di_y + int(13 * scale) + lens_size],
        fill=(14, 18, 24, 255)
    )
    
    return device_img, pw, ph, corner_radius

def stamp_device_with_shadow(comp: Image.Image, device_img: Image.Image, px: int, py: int, pw: int, ph: int, corner_radius: int, scale: float):
    """Renders soft dual-layer drop shadows and composites device onto transparent canvas."""
    width, height = comp.size
    shadow_layer = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow_layer)
    sdraw.rounded_rectangle(
        [px, py + int(24 * scale), px + pw, py + ph + int(24 * scale)],
        radius=corner_radius, fill=(0, 0, 0, 190)
    )
    sdraw.rounded_rectangle(
        [px, py + int(8 * scale), px + pw, py + ph + int(8 * scale)],
        radius=corner_radius, fill=(0, 0, 0, 140)
    )
    comp.alpha_composite(shadow_layer.filter(ImageFilter.GaussianBlur(int(44 * scale))))
    comp.paste(device_img, (px, py), device_img)

def generate_header_asset(width: int, height: int, output_png_path: str, screenshot_path: str):
    """
    Generate Product Page Header Asset:
    Single prominent centered device setting the calm, dignified brand tone.
    Safe area: Central column preserved for portrait mobile display.
    """
    print(f"\n--- Generating Header: {output_png_path} ({width} × {height} px) ---")
    
    if not os.path.exists(screenshot_path):
        raise FileNotFoundError(f"Screenshot not found at {screenshot_path}")
        
    screen_img = Image.open(screenshot_path).convert("RGBA")
    canvas = create_base_canvas(width, height)
    comp = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    
    # Scale relative to standard header height 1646
    S = height / 1646.0
    mock_h = int(1480 * S)
    
    dev, pw, ph, cr = render_device(screen_img, mock_h, S)
    phone_x = (width - pw) // 2
    phone_y = (height - ph) // 2
    
    stamp_device_with_shadow(comp, dev, phone_x, phone_y, pw, ph, cr, S)
    
    canvas_rgba = canvas.convert("RGBA")
    canvas_rgba.alpha_composite(comp)
    final_rgb = canvas_rgba.convert("RGB")
    
    os.makedirs(os.path.dirname(output_png_path), exist_ok=True)
    final_rgb.save(output_png_path, "PNG")
    file_size_kb = os.path.getsize(output_png_path) / 1024
    print(f"Saved Header (24-bit RGB, no alpha): {output_png_path} ({width} × {height} px, {file_size_kb:.1f} KB)")

def generate_search_result_asset(
    width: int,
    height: int,
    output_png_path: str,
    screen_aac_path: str,
    screen_hud_path: str
):
    """
    Generate App Store Search Result Creative Asset:
    Dual-device balanced showcase communicating Sotto's dual value at a glance:
      - Left: Dignified AAC Speech Board
      - Right: Two-Way Partner Crisis Triage HUD
    Safe area: Fully centered within safe zone, zero clipping on search cards.
    """
    print(f"\n--- Generating Search Result: {output_png_path} ({width} × {height} px) ---")
    
    screen_aac = Image.open(screen_aac_path).convert("RGBA")
    screen_hud = Image.open(screen_hud_path).convert("RGBA")
    
    canvas = create_base_canvas(width, height, glow_spread=0.52)
    comp = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    
    # Scale relative to 3:2 master height (2560 px)
    scale = height / 2560.0
    mock_h = int(2050 * scale)
    dev_scale = scale * 1.38
    
    dev_aac, pw_aac, ph_aac, cr_aac = render_device(screen_aac, mock_h, dev_scale)
    dev_hud, pw_hud, ph_hud, cr_hud = render_device(screen_hud, mock_h, dev_scale)
    
    gap = int(120 * scale)
    total_w = pw_aac + gap + pw_hud
    start_x = (width - total_w) // 2
    py = (height - ph_aac) // 2
    
    stamp_device_with_shadow(comp, dev_aac, start_x, py, pw_aac, ph_aac, cr_aac, dev_scale)
    stamp_device_with_shadow(comp, dev_hud, start_x + pw_aac + gap, py, pw_hud, ph_hud, cr_hud, dev_scale)
    
    canvas_rgba = canvas.convert("RGBA")
    canvas_rgba.alpha_composite(comp)
    final_rgb = canvas_rgba.convert("RGB")
    
    os.makedirs(os.path.dirname(output_png_path), exist_ok=True)
    final_rgb.save(output_png_path, "PNG")
    file_size_kb = os.path.getsize(output_png_path) / 1024
    print(f"Saved Search Result (24-bit RGB, no alpha): {output_png_path} ({width} × {height} px, {file_size_kb:.1f} KB)")

def main():
    screen_aac = "assets/screenshots/iphone_medium_dynamic_island/01_aac_speech_board.png"
    screen_hud = "assets/screenshots/iphone_medium_dynamic_island/02_two_way_partner_triage.png"
    
    if not os.path.exists(screen_aac):
        raise FileNotFoundError(f"Required screenshot not found at {screen_aac}. Run with --capture first.")
    if not os.path.exists(screen_hud):
        screen_hud = screen_aac
        
    print("===================================================================")
    print("Generating Apple App Store Product Page Information Creative Assets")
    print("===================================================================")
    
    # -------------------------------------------------------------------------
    # 1. Product Page Header Assets (Supported sizes: 3840 × 1646 & 5244 × 2950)
    # -------------------------------------------------------------------------
    # Dedicated 21:9 Header
    generate_header_asset(3840, 1646, "assets/app_store_header_3840x1646.png", screen_aac)
    # Universal 16:9 Header
    generate_header_asset(5244, 2950, "assets/app_store_universal_5244x2950.png", screen_aac)
    
    # -------------------------------------------------------------------------
    # 2. Search Result Assets (Supported sizes: 3840 × 2560, 1920 × 1280 & 5244 × 2950)
    # -------------------------------------------------------------------------
    # Dedicated 3:2 High-Resolution Search Result
    generate_search_result_asset(3840, 2560, "assets/app_store_search_result_3840x2560.png", screen_aac, screen_hud)
    # Dedicated 3:2 Standard Search Result
    generate_search_result_asset(1920, 1280, "assets/app_store_search_result_1920x1280.png", screen_aac, screen_hud)
    # Universal 16:9 Search Result
    generate_search_result_asset(5244, 2950, "assets/app_store_search_result_5244x2950.png", screen_aac, screen_hud)
    
    print("\n✅ All Product Page Information assets successfully generated!")

if __name__ == "__main__":
    main()
