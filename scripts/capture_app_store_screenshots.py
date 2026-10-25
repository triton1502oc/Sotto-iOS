#!/usr/bin/env python3
"""
App Store Connect Screenshot Automation for Sotto (iOS & iPadOS)
================================================================
Captures pixel-perfect screenshots meeting Apple App Store Connect specifications:
  - iPad 13-inch Display: 2064 x 2752 px (Portrait), 24-bit RGB, No Alpha / Transparency
  - iPhone Dynamic Island (Medium Display): 1206 x 2622 px (Portrait), 24-bit RGB, No Alpha / Transparency

Screens Captured per Device:
  1. 01_aac_speech_board.png      - Main AAC communication grid with quick-speak bar & safety card
  2. 02_two_way_partner_triage.png - Two-Way Speak HUD / 180° flip crisis triage (Yes/No/Not sure/Stop)
  3. 03_why_finder_tree.png        - Why Finder root-cause inquiry tree
  4. 04_whylog_analytics.png       - On-device private Why Log & 30-day pattern analytics
  5. 05_bystander_safety_card.png  - Fullscreen high-contrast emergency hero card with TTS
"""

import os
import sys
import time
import json
import argparse
import subprocess
from PIL import Image

SCREENS = [
    {
        "filename": "01_aac_speech_board.png",
        "arg": "--screenshot-main",
        "description": "Main AAC Speech Board (Calm Communication Cards & Quick-Speak)"
    },
    {
        "filename": "02_two_way_partner_triage.png",
        "arg": "--screenshot-triage",
        "description": "Two-Way Partner Mode (Caregiver Yes/No Crisis Triage)"
    },
    {
        "filename": "03_why_finder_tree.png",
        "arg": "--screenshot-whyfinder",
        "description": "Why Finder Decision Tree (Root-Cause Inquiry)"
    },
    {
        "filename": "04_whylog_analytics.png",
        "arg": "--screenshot-whylog",
        "description": "Private Why Log & 30-Day Trends Analytics"
    },
    {
        "filename": "05_bystander_safety_card.png",
        "arg": "--screenshot-safety",
        "description": "Fullscreen Bystander Safety Hero Card"
    },
    {
        "filename": "06_voice_settings.png",
        "arg": "--screenshot-settings",
        "description": "Voice Settings & Sensory Palettes"
    }
]

def run(cmd):
    return subprocess.run(cmd, shell=True, capture_output=True, text=True)

def resolve_device(query_patterns, fallback_type="iphone"):
    """
    Dynamically finds an available simulator matching one of the query patterns.
    Prioritizes booted devices.
    """
    try:
        output = subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "-j"], text=True)
        data = json.loads(output)
        devices = []
        for runtime, dev_list in data.get("devices", {}).items():
            for d in dev_list:
                devices.append(d)

        # 1. Exact UDID match
        for pattern in query_patterns:
            for d in devices:
                if d["udid"].lower() == pattern.lower():
                    return d["udid"], d["name"]

        # 2. Name pattern match (preferring Booted)
        for pattern in query_patterns:
            matches = [d for d in devices if pattern.lower() in d["name"].lower()]
            if matches:
                matches.sort(key=lambda d: 0 if d["state"] == "Booted" else 1)
                return matches[0]["udid"], matches[0]["name"]
                
    except Exception as e:
        print(f"Warning: Failed to query simctl: {e}")
        
    return None, None

def ensure_device_booted(device_id):
    run(f"xcrun simctl boot {device_id} 2>/dev/null")
    # Clean Apple App Store status bar (9:41 AM, 100% battery, full signal)
    run(f'xcrun simctl status_bar {device_id} override --time "9:41" --batteryState charged --batteryLevel 100 --wifiBars 3 --cellularBars 4')

def capture_screen(device_id, arg, temp_png):
    for attempt in range(2):
        run(f"xcrun simctl terminate {device_id} com.amh.sotto 2>/dev/null")
        time.sleep(0.5)
        run(f"xcrun simctl launch {device_id} com.amh.sotto {arg}")
        time.sleep(4.5)
        run(f"xcrun simctl io {device_id} screenshot {temp_png}")
        if os.path.exists(temp_png):
            try:
                test_im = Image.open(temp_png)
                # Check for blank / unrendered screens (less than 1% non-black pixels)
                non_zero = sum(1 for p in test_im.getdata() if p[:3] != (0, 0, 0))
                if non_zero > 0.01 * test_im.width * test_im.height:
                    break
                print(f"  [Notice] Screen appeared unrendered (attempt {attempt + 1}), retrying...")
            except Exception:
                pass
        time.sleep(1.0)

def process_and_save(temp_png, target_png, expected_size):
    if not os.path.exists(temp_png):
        raise FileNotFoundError(f"Screenshot file {temp_png} was not generated.")
    
    img = Image.open(temp_png)
    
    # Standardize dimensions
    if img.size != expected_size:
        print(f"  [Notice] Resizing from {img.size} to {expected_size} using Lanczos")
        img = img.resize(expected_size, Image.Resampling.LANCZOS)
    
    # Flatten to strictly 24-bit RGB (No alpha / transparency)
    if img.mode != "RGB":
        img = img.convert("RGB")
    
    os.makedirs(os.path.dirname(target_png), exist_ok=True)
    img.save(target_png, format="PNG", optimize=True)
    
    size_kb = os.path.getsize(target_png) / 1024.0
    print(f"  ✓ Saved: {target_png} | {img.size[0]}×{img.size[1]} px | Mode: {img.mode} (No Alpha) | {size_kb:.1f} KB")

def main():
    parser = argparse.ArgumentParser(description="Capture Sotto App Store Screenshots")
    parser.add_argument("--iphone", help="iPhone simulator name pattern or UDID", default=None)
    parser.add_argument("--ipad", help="iPad simulator name pattern or UDID", default=None)
    args = parser.parse_args()

    print("=================================================================")
    print(" Sotto App Store Connect Screenshot Automation")
    print("=================================================================\n")
    
    iphone_patterns = [args.iphone] if args.iphone else [
        "iPhone 17", "iPhone 18 Pro", "iPhone 16 Pro", "iPhone 16", "iPhone"
    ]
    ipad_patterns = [args.ipad] if args.ipad else [
        "iPad Pro 13-inch", "iPad Air 13-inch", "iPad Pro (12.9-inch)", "iPad"
    ]

    iphone_udid, iphone_name = resolve_device(iphone_patterns, "iphone")
    ipad_udid, ipad_name = resolve_device(ipad_patterns, "ipad")

    if not iphone_udid:
        print("❌ Error: Could not find a suitable iPhone simulator.")
        sys.exit(1)
    if not ipad_udid:
        print("❌ Error: Could not find a suitable iPad simulator.")
        sys.exit(1)

    devices = [
        {
            "name": f"iPhone ({iphone_name})",
            "id": iphone_udid,
            "output_dir": "assets/screenshots/iphone_medium_dynamic_island",
            "expected_size": (1206, 2622)
        },
        {
            "name": f"iPad ({ipad_name})",
            "id": ipad_udid,
            "output_dir": "assets/screenshots/ipad_13_inch",
            "expected_size": (2064, 2752)
        }
    ]

    temp_dir = "/tmp/sotto_screenshots_raw"
    os.makedirs(temp_dir, exist_ok=True)
    captured_files = []

    for dev in devices:
        dev_name = dev["name"]
        dev_id = dev["id"]
        out_dir = dev["output_dir"]
        expected_size = dev["expected_size"]
        
        print(f"\n--- Processing Device: {dev_name} [{dev_id}] ({expected_size[0]}×{expected_size[1]}) ---")
        ensure_device_booted(dev_id)
        
        for screen in SCREENS:
            fname = screen["filename"]
            arg = screen["arg"]
            desc = screen["description"]
            
            print(f"\nCapturing: {desc} ({arg})...")
            raw_path = os.path.join(temp_dir, f"{dev_id}_{fname}")
            final_path = os.path.join(out_dir, fname)
            
            capture_screen(dev_id, arg, raw_path)
            process_and_save(raw_path, final_path, expected_size)
            captured_files.append((final_path, expected_size))

    print("\n=================================================================")
    print(" Verification & Summary")
    print("=================================================================")
    all_ok = True
    for path, exp_size in captured_files:
        im = Image.open(path)
        has_alpha = "A" in im.mode
        passed = (im.size == exp_size and not has_alpha)
        status = "OK" if passed else "FAILED"
        if not passed:
            all_ok = False
        print(f"[{status}] {path} -> {im.size} | Mode: {im.mode} | Alpha: {has_alpha}")

    if all_ok:
        print("\n✅ All required App Store screenshots successfully generated and verified!")
    else:
        print("\n⚠️ Some screenshots did not match expected specifications.")
        sys.exit(1)

if __name__ == "__main__":
    main()
