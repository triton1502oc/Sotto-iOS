#!/usr/bin/env python3
"""
Sotto Unified Asset Build & Verification Suite
=============================================
One-command regeneration, validation, and preparation of all Sotto iOS & iPadOS
app icons, screenshots, product page headers, and marketing creative assets.

Usage:
  ./scripts/build_assets.sh               # Generate creative assets & verify
  ./scripts/build_assets.sh --generate    # Generate headers, banners, iPad library
  ./scripts/build_assets.sh --verify      # Verify all existing assets against App Store specs
  ./scripts/build_assets.sh --capture     # Boot simulators and capture raw screenshots
  ./scripts/build_assets.sh --all         # Full pipeline: capture -> generate -> verify
"""

import os
import sys
import argparse
import subprocess
from pathlib import Path
from PIL import Image

REPO_ROOT = Path(__file__).resolve().parent.parent

SPECIFICATIONS = [
    # (relative_path, expected_dimensions, allow_alpha, category)
    (
        "Sotto/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png",
        (1024, 1024), False, "App Icon (App Store & Xcode)"
    ),
    (
        "assets/app_icon_512.png",
        (512, 512), True, "App Icon (512px RGBA Web/Mockup)"
    ),
    (
        "assets/sotto_ios_banner.png",
        (1280, 640), False, "GitHub README Banner (Standard)"
    ),
    (
        "assets/sotto_ios_banner@2x.png",
        (2560, 1280), False, "GitHub README Banner (Retina 2x)"
    ),
    (
        "assets/app_store_header_3840x1646.png",
        (3840, 1646), False, "Product Page Header (21:9 Ultrawide)"
    ),
    (
        "assets/app_store_universal_5244x2950.png",
        (5244, 2950), False, "Product Page Header (16:9 Universal)"
    ),
    (
        "assets/app_store_search_result_3840x2560.png",
        (3840, 2560), False, "Search Result Asset (3:2 Retina)"
    ),
    (
        "assets/app_store_search_result_1920x1280.png",
        (1920, 1280), False, "Search Result Asset (3:2 Standard)"
    ),
    (
        "assets/app_store_search_result_5244x2950.png",
        (5244, 2950), False, "Search Result Asset (16:9 Universal)"
    ),
    (
        "assets/screenshots/iphone_medium_dynamic_island/01_aac_speech_board.png",
        (1206, 2622), False, "iPhone Screenshot 01 (Speech Grid)"
    ),
    (
        "assets/screenshots/iphone_medium_dynamic_island/02_two_way_partner_triage.png",
        (1206, 2622), False, "iPhone Screenshot 02 (Partner Triage)"
    ),
    (
        "assets/screenshots/iphone_medium_dynamic_island/03_why_finder_tree.png",
        (1206, 2622), False, "iPhone Screenshot 03 (Why Finder)"
    ),
    (
        "assets/screenshots/iphone_medium_dynamic_island/04_whylog_analytics.png",
        (1206, 2622), False, "iPhone Screenshot 04 (Why Log)"
    ),
    (
        "assets/screenshots/iphone_medium_dynamic_island/05_bystander_safety_card.png",
        (1206, 2622), False, "iPhone Screenshot 05 (Safety Hero Card)"
    ),
    (
        "assets/screenshots/ipad_13_inch/01_aac_speech_board.png",
        (2064, 2752), False, "iPad 13\" Screenshot 01 (Speech Grid)"
    ),
    (
        "assets/screenshots/ipad_13_inch/02_two_way_partner_triage.png",
        (2064, 2752), False, "iPad 13\" Screenshot 02 (Partner Triage)"
    ),
    (
        "assets/screenshots/ipad_13_inch/03_why_finder_tree.png",
        (2064, 2752), False, "iPad 13\" Screenshot 03 (Why Finder)"
    ),
    (
        "assets/screenshots/ipad_13_inch/04_whylog_analytics.png",
        (2064, 2752), False, "iPad 13\" Screenshot 04 (Why Log)"
    ),
    (
        "assets/screenshots/ipad_13_inch/05_bystander_safety_card.png",
        (2064, 2752), False, "iPad 13\" Screenshot 05 (Safety Hero Card)"
    ),
    (
        "assets/ipad/screenshot_13inch_portrait_2064x2752.png",
        (2064, 2752), False, "iPad 13\" Portrait (2064x2752)"
    ),
    (
        "assets/ipad/screenshot_13inch_landscape_2752x2064.png",
        (2752, 2064), False, "iPad 13\" Landscape Showcase (2752x2064)"
    ),
    (
        "assets/ipad/screenshot_12_9inch_portrait_2048x2732.png",
        (2048, 2732), False, "iPad 12.9\" Portrait (2048x2732)"
    ),
    (
        "assets/ipad/screenshot_12_9inch_landscape_2732x2048.png",
        (2732, 2048), False, "iPad 12.9\" Landscape Showcase (2732x2048)"
    ),
    (
        "assets/ipad/app_preview_portrait_1200x1600.png",
        (1200, 1600), False, "iPad App Preview Portrait (1200x1600)"
    ),
    (
        "assets/ipad/app_preview_landscape_1600x1200.png",
        (1600, 1200), False, "iPad App Preview Landscape (1600x1200)"
    ),
]

def run_command(cmd, desc):
    print(f"\n▶ Running: {desc}...")
    res = subprocess.run(cmd, cwd=str(REPO_ROOT), shell=True)
    if res.returncode != 0:
        print(f"❌ Failed: {desc} (Exit code {res.returncode})")
        return False
    return True

def capture_screenshots():
    return run_command("python3 scripts/capture_app_store_screenshots.py", "Capture Simulator Screenshots")

def generate_headers():
    return run_command("python3 scripts/generate_app_store_headers.py", "Generate Product Page Headers & Search Results")

def generate_ipad():
    return run_command("python3 scripts/generate_ipad_assets.py", "Generate iPad Asset Library")

def generate_banners():
    return run_command("python3 scripts/generate_header_asset.py", "Generate GitHub Banners")

def verify_all_assets():
    print("\n" + "=" * 80)
    print(" Sotto Asset Library Compliance Verification (Apple App Store Connect)")
    print("=" * 80)
    
    total = len(SPECIFICATIONS)
    passed = 0
    failed = 0
    
    header = f"{'Status':<8} | {'Category / Name':<38} | {'Dimensions':<13} | {'Size':<9} | {'No Alpha'}"
    print(header)
    print("-" * 80)

    for rel_path, exp_dim, allow_alpha, category in SPECIFICATIONS:
        full_path = REPO_ROOT / rel_path
        if not full_path.exists():
            print(f"{'MISSING':<8} | {category:<38} | {'--':<13} | {'--':<9} | N/A")
            failed += 1
            continue

        try:
            im = Image.open(full_path)
            dim = im.size
            has_alpha = "A" in im.mode
            size_kb = full_path.stat().st_size / 1024.0

            dim_ok = (dim == exp_dim)
            alpha_ok = allow_alpha or (not has_alpha)

            if dim_ok and alpha_ok:
                status = "PASS"
                passed += 1
            else:
                status = "FAIL"
                failed += 1

            alpha_str = "YES (Allowed)" if allow_alpha else ("NO (Opaque)" if not has_alpha else "ALPHA DETECTED!")
            print(f"{status:<8} | {category:<38} | {f'{dim[0]}x{dim[1]}':<13} | {f'{size_kb:.1f} KB':<9} | {alpha_str}")

        except Exception as e:
            print(f"{'ERROR':<8} | {category:<38} | Error: {e}")
            failed += 1

    print("-" * 80)
    print(f"Summary: {passed}/{total} Passed, {failed} Failed.")
    print("=" * 80)
    return (failed == 0)

def main():
    parser = argparse.ArgumentParser(description="Sotto Unified Asset Pipeline")
    parser.add_argument("--capture", action="store_true", help="Capture simulator screenshots")
    parser.add_argument("--generate", action="store_true", help="Generate headers, iPad assets, and banners")
    parser.add_argument("--verify", action="store_true", help="Verify asset dimensions, RGB mode, and alpha")
    parser.add_argument("--all", action="store_true", help="Full pipeline: capture, generate, and verify")
    args = parser.parse_args()

    # Default action if no flags provided: generate & verify
    if not (args.capture or args.generate or args.verify or args.all):
        args.generate = True
        args.verify = True

    if args.all or args.capture:
        if not capture_screenshots():
            sys.exit(1)

    if args.all or args.generate:
        if not generate_headers():
            sys.exit(1)
        if not generate_ipad():
            sys.exit(1)
        if not generate_banners():
            sys.exit(1)

    if args.all or args.verify:
        if not verify_all_assets():
            sys.exit(1)

    print("\n🎉 All assets processed and verified successfully!\n")

if __name__ == "__main__":
    main()
