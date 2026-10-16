# Apple App Store Listing & Submission Guide

### TL;DR
Ready-to-use metadata, descriptions, keywords, screenshot specifications, and privacy nutrition label answers for submitting Sotto to Apple App Store Connect.

---

## 1. App Store Connect Metadata

### App Details
* **App Name:** `Sotto` *(5 / 30 characters)*
* **Subtitle:** `Calm Yes/No for Meltdowns` *(25 / 30 characters)*
* **Primary Category:** `Accessibility` or `Utilities`
* **Secondary Category:** `Productivity`
* **Age Rating:** `4+` (No violence, no objectionable content, no user tracking)
* **Copyright:** `2026 Budi Aprianto`
* **Content Rights (Third-Party Content):** Select **"No"** (Core app uses 100% native Apple frameworks, SF Symbols, and local storage; zero external copyrighted assets).

### Promotional Text *(167 / 170 characters)*
```text
Calm yes/no communication for caregivers reaching autistic loved ones in shutdowns, paired with a dignified low-stimulus AAC speech board & Action Button launch.
```

### Keywords *(Comma-separated, no spaces after commas, 77 / 100 characters)*
```text
aac,autism,shutdown,meltdown,nonspeaking,yesno,caregiver,tts,offline,autistic
```

### Full Description *(Markdown & Plain Text compliant)*
```text
When speech is hard, tap instead.

Built by a father in Singapore for his two autistic sons (22 & 15) who can speak but not always. During meltdown, operating a phone is too hard. So I operate Sotto on MY phone, they tap Yes/No/Wait to pinpoint — issue resolved.

Two modes, one family system:

MODE 1 - DAILY (He holds his phone):
Self-operated dignified AAC for complex info. Tap cards, multi-line Quick-Speak Bar, long-press giant fullscreen. Universal iPhone & iPad.

MODE 2 - MELTDOWN (You hold YOUR phone):
You hold your phone. Tap partner, Flip 180° to face him, he taps Yes/No/Not sure/Stop. Direct pinpoint, no branching tree during crisis. This is what works at home.

Crafted for sensory needs:
• 5 Sensory Themes: Charcoal, OLED Pure Black, Warm Amber Low Strain, Slate Navy, Soft Parchment — WCAG AAA
• Dignified Speech: AVSpeechSynthesizer with Samantha, Siri, Ava, Damayanti, digit-by-digit phone TTS for Safety card
• Attention Chime: D5->A5 musical + haptics
• Safety Bystander Card: 🛡️ badge, high-contrast amber #251E14/#FFB74D, digit-by-digit phone TTS
• Two-Way HUD: Talk first during crisis, Why Finder second tab post-crisis
• Why Log & Trends: After Yes/No resolves, log root cause locally
• QR Offline Sharing: SOTTO:v1:... between iOS & Android, zero cloud
• Backup v2: Granular JSON merge/replace
• 100% Offline, Zero Trackers, Telemetry v3 opt-in with payload preview & 14-day PMF survey

Free. Private. GPL-3.0 with App Store exception. Sotto is not a medical device and does not provide medical advice, diagnosis, or treatment. It is an assistive communication tool.

github.com/triton1502oc/Sotto-iOS | Android available
```

### What's New *(v1.7.2)*
```text
• Modernized Caregiver HUD: Elevated 2x2 response dock with tactile haptics and smooth 180° flip animation.
• 1-Tap Trigger Logger: Fast on-device logging to Why Log following crisis resolution.
• Streamlined Main Screen: Modern top action bar, single-row QuickSpeak capsule dock, and drag-and-drop card reordering in Edit Mode.
• Compact Card Density: Opt-in 1.25:1 card density option in Settings.
• 3-Tab Categorized Settings: Reorganized settings into Voice, Appearance, and Data with in-context question tree editing.
• Sensory Theme Parity: All modals dynamically adapt to your selected sensory palette.
```

### URLs
* **Support URL:** `https://github.com/triton1502oc/Sotto-iOS/issues`
* **Marketing URL:** `https://github.com/triton1502oc/Sotto-iOS`
* **Privacy Policy URL:** `https://github.com/triton1502oc/Sotto-iOS/blob/main/PRIVACY_POLICY.md`
* **Video Demo (YouTube):** `https://youtu.be/Qk76_dPfbko`
* **Video Demo (YouTube Shorts):** `https://youtube.com/shorts/7jKnRHIvJv8`

---

## 2. Screenshot & Media Requirements

| Device Display / Asset | Dimensions | Status / Location |
|---|---|---|
| **iPhone with Dynamic Island (medium display)** (iPhone 16, 17) | 1206 x 2622 px (Portrait, 24-bit RGB, No Alpha) | **Ready to Upload:** `assets/screenshots/iphone_medium_dynamic_island/*.png` |
| **13-inch iPad Displays** (iPad Pro 13-inch M4/M5, iPad Air 13-inch) | 2064 x 2752 px (Portrait, 24-bit RGB, No Alpha) | **Ready to Upload:** `assets/screenshots/ipad_13_inch/*.png` |
| **iPhone 6.9" / 6.7" Display** (iPhone 16 Pro Max, 15 Pro Max) | 1320 x 2868 px or 1290 x 2796 px | Supported |
| **iPad Pro 12.9" Display** | 2048 x 2732 px (Portrait) | Available: `assets/ipad/screenshot_12_9inch_*` |
| **App Icon** | 1024 x 1024 px (PNG, no transparency) | Included in Assets.xcassets |
| **Product Page Header** | 3840 x 1646 px (21:9, 24-bit RGB, no alpha) | Available: `assets/app_store_header_3840x1646.png` |
| **Product Page Header (Universal)** | 5244 x 2950 px (16:9, 24-bit RGB, no alpha) | Available: `assets/app_store_universal_5244x2950.png` |
| **Search Result Asset (3:2 Retina)** | 3840 x 2560 px (3:2, 24-bit RGB, no alpha) | Available: `assets/app_store_search_result_3840x2560.png` |
| **Search Result Asset (3:2 Standard)** | 1920 x 1280 px (3:2, 24-bit RGB, no alpha) | Available: `assets/app_store_search_result_1920x1280.png` |
| **Search Result Asset (Universal)** | 5244 x 2950 px (16:9, 24-bit RGB, no alpha) | Available: `assets/app_store_search_result_5244x2950.png` |
| **App Store Preview Video (Master)** | 1920 x 1080 px (16:9 Landscape @ 30fps) | ✅ Ready: [`demo/sotto_app_store_preview.mp4`](../demo/sotto_app_store_preview.mp4) ([YouTube](https://youtu.be/Qk76_dPfbko)) |
| **Social / Vertical Video (Shorts/Reels)** | 1080 x 1920 px (9:16 Portrait @ 30fps) | ✅ Ready: [`demo/sotto_vertical_preview.mp4`](../demo/sotto_vertical_preview.mp4) ([YouTube Shorts](https://youtube.com/shorts/7jKnRHIvJv8)) |

### Screenshot Set Organization (App Store Review Compliant)
Both folders contain 5 sequential screens matching App Store Connect review requirements:
1. `01_aac_speech_board.png` – Low-stimulus AAC speech grid with Quick-Speak bar
2. `02_two_way_partner_triage.png` – Caregiver yes/no crisis check-in & 180° tabletop partner mode
3. `03_why_finder_tree.png` – Why Finder systematic root-cause discovery tree
4. `04_whylog_analytics.png` – Private on-device Why Log with 30-day pattern insights
5. `05_bystander_safety_card.png` – Fullscreen Bystander Hero card with TTS readout

### Re-generating and Verifying Assets
To re-generate all creative assets or verify App Store compliance at any time:
```bash
./scripts/build_assets.sh          # Re-generate creative assets & verify
./scripts/build_assets.sh --all    # Full simulator capture, generation, and verification
./scripts/build_assets.sh --verify # Verification check only
```


## 3. App Privacy Questionnaire (App Store Connect)

When completing the **App Privacy** section in App Store Connect:

1. **Do you or your third-party partners collect data from this app?**  
   👉 Select **"No, we do not collect data from this app"**.
2. **Resulting Label:** **Data Not Collected**.

---

## 4. App Review Notes (Guideline 2.1 Response & App Review Information)

When submitting for App Review or responding to Guideline 2.1 inquiries, provide this information in the **Notes** field and **Resolution Center**:

```text
Guideline 2.1 - App Information & Completeness:

1. App Functionality & Screen Recording:
A screen recording captured on a physical iPad running the latest iPadOS is provided/attached demonstrating the complete launch and typical user flow (Sotto is a Universal app supporting both iPad and iPhone):
- Launch from Home Screen directly into AAC Speech Board.
- Tapping phrase cards and QuickSpeak text bar with native AVSpeechSynthesizer text-to-speech.
- Opening Two-Way Caregiver Partner Mode with 180° tabletop rotation dock (Yes, No, Not sure, Stop).
- Navigating the Why Finder guided root-cause crisis tree and local Why Log.
- Accessing the Bystander Safety Card (emergency communication).
- Accessing Settings (sensory themes and voice options).
Note on specific flows:
- Accounts / Login / Account Deletion: Not applicable. Sotto requires no accounts, registration, or logins. All user data is stored strictly on-device.
- User-Generated Content (UGC) & Reporting: Not applicable. Sotto is a single-user assistive speech tool with no public feeds, multi-user interaction, or social sharing. Custom phrase cards are stored strictly locally for personal use.
- Paid Content: Not applicable. Sotto is 100% free with zero in-app purchases, subscriptions, or paywalls.

2. Purpose & Target Audience:
Sotto is an assistive augmentative and alternative communication (AAC) application designed for autistic teens and adults, situational non-speaking individuals, and family caregivers navigating acute sensory meltdowns or verbal shutdowns. Traditional AAC tools rely on multi-tier pediatric menus that cause cognitive overload during crisis. Sotto provides a dignified, low-stimulus speech board for daily communication and a 2-way binary response HUD (Yes/No/Wait) so caregivers can de-escalate crises without verbal pressure.

3. Setup & Access Instructions:
No setup, onboarding, login credentials, or sample files are required. The app opens immediately in a ready-to-use functional state:
- Tap any card to speak via iOS native text-to-speech.
- Tap '🤝' in top bar to open Two-Way Partner Mode with 180° rotation dock.
- Tap 'Why Finder' tab inside Partner Mode for guided root-cause triage.
- Tap '🛡️' in top bar for the Emergency Bystander Card.
- Tap '⚙️' for sensory themes and speech settings.

4. External Services & Platforms:
Zero external services, third-party APIs, cloud backends, payment processors, or AI services are used. Sotto operates 100% offline using only native Apple frameworks:
- AVFoundation (AVSpeechSynthesizer) for on-device Text-to-Speech.
- Speech framework for optional on-device speech-to-text dictation.
- CoreHaptics / UIKit for tactile sensory feedback.
- CoreImage for offline QR code deck sharing.
- UserDefaults for local on-device phrase storage.

5. Regional Differences:
Sotto functions consistently and identically across all regions worldwide. The app includes built-in English and Indonesian localizations and supports all iOS system voices with zero regional or geofenced variations.

6. Regulated Industry & Third-Party Materials:
- Assistive Tool (Not a Medical Device): Sotto does not operate in a regulated healthcare or financial industry. It is an assistive communication utility and does not provide medical diagnosis, treatment, or clinical monitoring.
- No Protected Third-Party Material: The app contains no copyrighted third-party material or proprietary assets. Icons use Apple SF Symbols, and source code is original (GPL-3.0 with App Store exception).
```

---

## 5. Apple Accessibility & Inclusivity Editorial Pitch

Submit this pitch to Apple Developer Relations / App Store Editorial under the **Inclusivity & Accessibility** nomination:

### Pitch Summary:
* **App:** Sotto
* **Category:** Accessibility, Utilities, Productivity
* **Target Audience:** Autistic teens & adults, situational non-speaking users, parents & caregivers navigating meltdowns.

### What Makes Sotto Unique:
1. **Crisis-First Interaction Design**: Traditional AAC apps assume calm, continuous symbol communication. Sotto is purpose-built for the acute verbal shutdown / sensory meltdown crisis loop. The Two-Way HUD with 180° tabletop rotation gives families an immediate, low-demand binary check-in (`Yes`, `No`, `Not sure`, `Stop`) with zero cognitive pressure.
2. **Adult Neurodivergent Dignity**: Mature typography, high-contrast sensory-calm palettes (Charcoal, OLED Pure Black, Warm Amber, Slate Navy, Soft Parchment), and zero patronizing pediatric cartoon icons.
3. **Deep Apple Ecosystem Integration**: 1-press hardware launch via the iPhone Action Button, Accessibility Back Tap, and Siri Shortcuts using native `AppIntents`.
4. **100% Offline Privacy Guarantee**: Zero cloud accounts, zero ads, zero trackers. Rated "Data Not Collected" on App Privacy labels. Features high-density offline QR deck sharing directly between devices without internet.

