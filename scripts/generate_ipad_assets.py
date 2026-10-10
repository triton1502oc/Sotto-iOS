#!/usr/bin/env python3
"""
Generate Apple App Store Asset Library for iPad 12.9" and 13" Displays
======================================================================
Generates high-resolution App Store screenshots and App Previews strictly conforming
to Apple App Store Connect specifications:
https://developer.apple.com/app-store/asset-best-practices/

SUPPORTED SPECIFICATIONS:
  1. App Previews:
     - 1600 × 1200 px (Landscape)
     - 1200 × 1600 px (Portrait)
  2. App Screenshots:
     - 2752 × 2064 px (13" iPad Pro - Landscape)
     - 2064 × 2752 px (13" iPad Pro - Portrait)
     - 2732 × 2048 px (12.9" iPad Pro - Landscape)
     - 2048 × 2732 px (12.9" iPad Pro - Portrait)

FORMAT REQUIREMENTS:
  - Format: PNG (24-bit RGB)
  - Color Profile: sRGB
  - Alpha Channel: None (hasAlpha: no)
"""

import os
import sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

def make_portrait_direct(w: int, h: int, src_img: Image.Image) -> Image.Image:
    """Resize portrait screenshot to exact target dimensions using Lanczos filter and flatten to RGB."""
    resized = src_img.resize((w, h), Image.Resampling.LANCZOS)
    return resized.convert("RGB")

def make_showcase_landscape(w: int, h: int, src_img: Image.Image) -> Image.Image:
    """
    Renders the portrait iPad screenshot centered inside a precision iPad Pro
    enclosure with soft ambient drop shadows on Sotto's dark-neutral canvas.
    """
    # 1. Base Gradient Canvas (Calming charcoal #0E1114 with subtle sage radial glow)
    y_coords, x_coords = np.ogrid[:h, :w]
    base_r, base_g, base_b = 14.0, 17.0, 20.0
    center_x, center_y = w / 2.0, h / 2.0
    dist = np.sqrt((x_coords - center_x) ** 2 + (y_coords - center_y) ** 2) / (w * 0.45)
    factor_glow = np.clip(1.0 - dist, 0.0, 1.0) ** 1.8
    glow_r = factor_glow * 22.0
    glow_g = factor_glow * 34.0
    glow_b = factor_glow * 26.0

    final_r = np.clip(base_r + glow_r, 0, 255).astype(np.uint8)
    final_g = np.clip(base_g + glow_g, 0, 255).astype(np.uint8)
    final_b = np.clip(base_b + glow_b, 0, 255).astype(np.uint8)
    canvas = Image.fromarray(np.dstack((final_r, final_g, final_b)))

    comp = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    scale = h / 2064.0

    # Device sizing: ~88% of canvas height
    mock_h = int(h * 0.88)
    mock_w = int(mock_h * (src_img.width / src_img.height))
    screen_resized = src_img.resize((mock_w, mock_h), Image.Resampling.LANCZOS).convert("RGBA")

    bezel = max(8, int(18 * scale))
    device_w = mock_w + bezel * 2
    device_h = mock_h + bezel * 2
    radius = max(24, int(52 * scale))

    dev_x = (w - device_w) // 2
    dev_y = (h - device_h) // 2

    # Layered soft ambient drop shadows
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    sdraw.rounded_rectangle(
        [dev_x, dev_y + int(28 * scale), dev_x + device_w, dev_y + device_h + int(28 * scale)],
        radius=radius, fill=(0, 0, 0, 180)
    )
    sdraw.rounded_rectangle(
        [dev_x, dev_y + int(10 * scale), dev_x + device_w, dev_y + device_h + int(10 * scale)],
        radius=radius, fill=(0, 0, 0, 130)
    )
    comp.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(int(40 * scale))))

    # iPad Pro Enclosure Frame (Dark slate titanium)
    draw = ImageDraw.Draw(comp)
    draw.rounded_rectangle(
        [dev_x, dev_y, dev_x + device_w, dev_y + device_h],
        radius=radius,
        fill=(24, 27, 32, 255),
        outline=(70, 78, 90, 255),
        width=max(2, int(3 * scale))
    )

    # Inner specular chamfer highlight
    inset = max(1, int(2 * scale))
    draw.rounded_rectangle(
        [dev_x + inset, dev_y + inset, dev_x + device_w - inset, dev_y + device_h - inset],
        radius=radius - inset,
        outline=(95, 105, 120, 100),
        width=max(1, int(2 * scale))
    )

    # Mask screen to iPad rounded corners
    screen_mask = Image.new("L", (mock_w, mock_h), 0)
    mdraw = ImageDraw.Draw(screen_mask)
    inner_radius = max(16, int(36 * scale))
    mdraw.rounded_rectangle([0, 0, mock_w, mock_h], radius=inner_radius, fill=255)

    screen_x = dev_x + bezel
    screen_y = dev_y + bezel
    comp.paste(screen_resized, (screen_x, screen_y), screen_mask)

    # Subtle front camera sensor dot
    cam_size = max(4, int(8 * scale))
    cam_x = dev_x + device_w // 2
    cam_y = dev_y + bezel // 2
    draw.ellipse(
        [cam_x - cam_size // 2, cam_y - cam_size // 2, cam_x + cam_size // 2, cam_y + cam_size // 2],
        fill=(15, 15, 18, 255)
    )

    canvas.paste(comp, (0, 0), comp)
    return canvas.convert("RGB")

def make_seamless_landscape(w: int, h: int, src_img: Image.Image) -> Image.Image:
    """
    Renders full-height edge-to-edge UI with Sotto's dark background (#121212)
    seamlessly extending along the left and right wings.
    """
    canvas = Image.new("RGB", (w, h), (18, 18, 18))
    mock_h = h
    mock_w = int(mock_h * (src_img.width / src_img.height))
    screen_resized = src_img.resize((mock_w, mock_h), Image.Resampling.LANCZOS).convert("RGB")
    x_offset = (w - mock_w) // 2
    canvas.paste(screen_resized, (x_offset, 0))
    return canvas

def generate_assets(source_path: str, output_dir: str):
    src_file = Path(source_path)
    if not src_file.exists():
        raise FileNotFoundError(f"Source screenshot not found: {source_path}")

    out_base = Path(output_dir)
    out_base.mkdir(parents=True, exist_ok=True)
    out_seamless = out_base / "seamless"
    out_seamless.mkdir(parents=True, exist_ok=True)

    print(f"Loading source screenshot: {src_file}")
    src_img = Image.open(src_file).convert("RGBA")
    print(f"Source image dimensions: {src_img.width} × {src_img.height} px")

    # Specifications
    targets = [
        # (category, filename, width, height, is_portrait)
        ("App Screenshot (13\" iPad Pro - Portrait)", "screenshot_13inch_portrait_2064x2752.png", 2064, 2752, True),
        ("App Screenshot (13\" iPad Pro - Landscape)", "screenshot_13inch_landscape_2752x2064.png", 2752, 2064, False),
        ("App Screenshot (12.9\" iPad Pro - Portrait)", "screenshot_12_9inch_portrait_2048x2732.png", 2048, 2732, True),
        ("App Screenshot (12.9\" iPad Pro - Landscape)", "screenshot_12_9inch_landscape_2732x2048.png", 2732, 2048, False),
        ("App Preview (Portrait)", "app_preview_portrait_1200x1600.png", 1200, 1600, True),
        ("App Preview (Landscape)", "app_preview_landscape_1600x1200.png", 1600, 1200, False),
    ]

    print("\n--- Generating iPad 12.9\" & 13\" Asset Library ---")
    for category, filename, w, h, is_portrait in targets:
        dest_path = out_base / filename
        if is_portrait:
            img = make_portrait_direct(w, h, src_img)
            img.save(dest_path, "PNG", optimize=True)
            size_kb = dest_path.stat().st_size / 1024
            print(f"  [OK] {category:<44} -> {filename:<45} ({w}×{h} px, {size_kb:.1f} KB, RGB opaque)")
        else:
            # Studio Showcase
            img_showcase = make_showcase_landscape(w, h, src_img)
            img_showcase.save(dest_path, "PNG", optimize=True)
            size_kb = dest_path.stat().st_size / 1024
            print(f"  [OK] {category:<44} -> {filename:<45} ({w}×{h} px, {size_kb:.1f} KB, RGB opaque)")

            # Seamless variation
            dest_seamless = out_seamless / filename
            img_seamless = make_seamless_landscape(w, h, src_img)
            img_seamless.save(dest_seamless, "PNG", optimize=True)
            size_seamless_kb = dest_seamless.stat().st_size / 1024
            print(f"  [OK] {category + ' (Seamless)':<44} -> seamless/{filename:<36} ({w}×{h} px, {size_seamless_kb:.1f} KB, RGB opaque)")

    print(f"\nAsset Library generation complete in: {out_base.resolve()}")

if __name__ == "__main__":
    default_src = "assets/screenshots/ipad_13_inch/01_aac_speech_board.png"
    default_out = "assets/ipad"

    src = sys.argv[1] if len(sys.argv) > 1 else default_src
    out = sys.argv[2] if len(sys.argv) > 2 else default_out

    generate_assets(src, out)
