# Sotto for iOS Asset Library

### TL;DR
This directory contains all canonical visual assets for Sotto on iOS & iPadOS, including Apple App Store Connect submission creatives, App Previews, localized screenshots, high-resolution app icons, and repository banners. Everything can be re-generated and verified with a single command:
```bash
./scripts/build_assets.sh
```

---

## 1. Directory Structure

```
assets/
├── app_icon_512.png                           # 512×512 RGBA web & marketing app icon
├── app_store_header_3840x1646.png             # 21:9 Product Page Header (Ultrawide)
├── app_store_universal_5244x2950.png          # 16:9 Product Page Header (Universal)
├── app_store_search_result_3840x2560.png      # 3:2 App Store Search Result Creative (Retina)
├── app_store_search_result_1920x1280.png      # 3:2 App Store Search Result Creative (Standard)
├── app_store_search_result_5244x2950.png      # 16:9 App Store Search Result Creative (Universal)
├── sotto_ios_banner.png                       # GitHub README Banner (1280×640)
├── sotto_ios_banner@2x.png                    # GitHub README Banner Retina 2x (2560×1280)
├── screenshots/
│   ├── iphone_medium_dynamic_island/          # iPhone 16 / 17 Display (1206×2622 px, 24-bit RGB)
│   │   ├── 01_aac_speech_board.png            # Main AAC speech board with Quick-Speak
│   │   ├── 02_two_way_partner_triage.png      # Caregiver yes/no crisis triage & 180° flip HUD
│   │   ├── 03_why_finder_tree.png             # Why Finder root-cause inquiry tree
│   │   ├── 04_whylog_analytics.png            # Private on-device Why Log 30-day trends
│   │   └── 05_bystander_safety_card.png       # Fullscreen high-contrast bystander safety card
│   └── ipad_13_inch/                          # 13" iPad Displays (2064×2752 px, 24-bit RGB)
│       ├── 01_aac_speech_board.png
│       ├── 02_two_way_partner_triage.png
│       ├── 03_why_finder_tree.png
│       ├── 04_whylog_analytics.png
│       └── 05_bystander_safety_card.png
└── ipad/                                      # iPad Pro Showcase & App Preview Library
    ├── screenshot_13inch_portrait_2064x2752.png
    ├── screenshot_13inch_landscape_2752x2064.png
    ├── screenshot_12_9inch_portrait_2048x2732.png
    ├── screenshot_12_9inch_landscape_2732x2048.png
    ├── app_preview_portrait_1200x1600.png
    ├── app_preview_landscape_1600x1200.png
    └── seamless/                              # Full-bleed edge variations
```

---

## 2. Re-generating and Submitting Assets

### One-Command Pipeline
To regenerate all creative assets (headers, search results, iPad previews, GitHub banners) from base screenshots and verify compliance:
```bash
./scripts/build_assets.sh
```

### Full Re-capture from Simulators
To boot iPhone and iPad simulators, capture fresh screenshots with clean status bars (9:41 AM, 100% battery), build creative assets, and verify:
```bash
./scripts/build_assets.sh --all
```

### Verification Only
To audit existing assets against Apple App Store specifications:
```bash
./scripts/build_assets.sh --verify
```

---

## 3. App Store Connect Upload Mapping

When submitting Sotto in [App Store Connect](https://appstoreconnect.apple.com):

| App Store Section | Specification | Recommended File |
|---|---|---|
| **App Icon** | 1024 × 1024 px, 24-bit RGB, No Alpha | `Sotto/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` |
| **Product Page Header** | 3840 × 1646 px (21:9) or 5244 × 2950 px (16:9) | `assets/app_store_header_3840x1646.png` |
| **Search Result Creative** | 3840 × 2560 px (3:2) or 1920 × 1280 px (3:2) | `assets/app_store_search_result_3840x2560.png` |
| **iPhone Screenshots (Medium)** | 1206 × 2622 px, 24-bit RGB, No Alpha | `assets/screenshots/iphone_medium_dynamic_island/*.png` |
| **iPad Pro 13" Screenshots** | 2064 × 2752 px, 24-bit RGB, No Alpha | `assets/screenshots/ipad_13_inch/*.png` |
| **iPad Pro 12.9" Screenshots** | 2048 × 2732 px (Portrait) or 2732 × 2048 px (Landscape) | `assets/ipad/screenshot_12_9inch_*` |
| **iPad App Previews** | 1200 × 1600 px (Portrait) or 1600 × 1200 px (Landscape) | `assets/ipad/app_preview_*` |

---

## 4. Technical Guardrails & Compliance

- **No Transparency / Zero Alpha**: Apple App Store Connect strictly rejects any screenshots or product page creatives containing an alpha channel. All assets are flattened to 24-bit RGB (`hasAlpha: no`).
- **WCAG 2.1 AAA Contrast**: Visuals adhere to Sotto's low-stimulus dark neutral palette (`Charcoal #0E1114`, `Sage #8EB292`, `Off-White #E6ECEF`).
- **Offline & Privacy Preserved**: No real user data or private information is ever rendered in marketing materials.
