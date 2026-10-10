# Apple App Store Listing & Submission Guide

### TL;DR
Ready-to-use metadata, descriptions, keywords, screenshot specifications, and privacy nutrition label answers for submitting Sotto to Apple App Store Connect.

---

## 1. App Store Connect Metadata

### App Details
* **App Name:** `Sotto - Assistive AAC Speech` *(29 / 30 characters)*
* **Subtitle:** `Calm Crisis Triage & Adult AAC` *(30 / 30 characters)*
* **Primary Category:** `Medical` or `Utilities`
* **Secondary Category:** `Productivity`
* **Age Rating:** `4+` (No violence, no objectionable content, no user tracking)
* **Copyright:** `2026 Budi Aprianto` (or `2026 <Your Name / Organization>`)
* **Content Rights (Third-Party Content):** Select **"No"** (Core app uses 100% native Apple frameworks, SF Symbols, and local storage; zero external copyrighted assets).

### Promotional Text *(159 / 170 characters)*
```text
Calm yes/no crisis triage for caregivers reaching autistic loved ones in shutdowns, paired with a dignified low-stimulus AAC speech board & Action Button launch.
```

### Keywords *(Comma-separated, no spaces after commas, 97 / 100 characters)*
```text
shutdown,meltdown,deescalation,sensory,mutism,nonverbal,crisis,triage,aphasia,overload,aac,autism,speech
```

### Full Description *(Markdown & Plain Text compliant, ~3,600 / 4,000 characters)*
```text
Sotto is a calm yes/no crisis navigation tool for caregivers, parents, and therapists to connect with autistic teens and adults during sensory overload, meltdowns, and verbal shutdowns — paired with a dignified, low-stimulation AAC speech board for daily communication and unclear speech support.

Created by a father of two autistic sons (ages 22 and 15), Sotto is built on lived experience: during meltdowns and shutdowns, processing complex questions or speaking is exhausting. Sotto bridges this divide with gentle binary choices, speech clarity support, zero open-ended demands, and instant hardware Action Button launch.

FOR CAREGIVERS, FAMILIES & THERAPISTS:

• Two-Way Speak HUD & 180° Tabletop Flip
During sensory overload or shutdowns, complex questions worsen distress. Caregivers speak naturally or choose a preset prompt, flip the device 180° face-to-face, and let their loved one tap giant response targets (Yes, No, Not sure, Stop) with voice confirmation. Zero cognitive load.

• Hardware Action Button & Siri Shortcuts
During acute freezes, navigating menus is difficult. Map the physical Action Button, iOS Back Tap, or Siri Shortcuts ("Open Sotto Emergency") to instantly launch crisis triage or safety cards eyes-free.

• Why Finder (Root-Cause Discovery Tree)
When distress causes are unclear, Why Finder provides a gentle yes/no tree to systematically uncover physical pain (with body locator), sensory overload, fatigue, or routine disruptions without demanding open-ended answers.

• Private On-Device Why Log & Trends
Resolved crisis sessions are logged 100% locally. Review 30-day patterns to identify recurring triggers, peak hours, and actionable interventions. Never uploaded to the cloud.

• Customizable Trees & Safe Sharing
Tailor questions to specific triggers using voice dictation. Export and share custom trees with teachers or therapists while keeping private crisis logs strictly excluded.

FOR NON-SPEAKING & UNCLEAR VOICES:

• Dignified Voice for Unclear Speech
Whether non-verbal, in a shutdown, or speaking with quiet, slurred, or dysarthric speech, Sotto provides a crisp, adult voice and high-contrast cards—free of childish cartoons.

• Safety & Bystander Hero Card
High-contrast banner for non-verbal episodes and medical contacts. Show fullscreen to bystanders or first responders with digit-by-digit emergency phone number TTS read aloud.

• Sensory Themes & Universal Grid
Sensory palettes (Charcoal, OLED Black, Warm Amber, Slate Navy, Soft Parchment) with WCAG AAA contrast. Responsive layouts support all orientations on iPhone and iPad.

• Quick-Speak Bar & Voice Dictation
Type spontaneous thoughts with auto-expanding text, one-tap speech, voice dictation, and one-touch card creation.

• Giant Fullscreen & Attention Chime
Display any phrase across the entire screen in giant text for noisy spaces. Sound a gentle two-tone chime and haptic vibration to politely capture attention before speaking.

• Natural Speech & Dual-Language TTS
Natural flagship voices with rate and pitch controls. Display cards in one language while speaking in another (e.g., English text spoken in Indonesian) via offline translation.

• Instant Offline QR Deck Sharing
Exchange communication decks between caregivers, therapists, and users completely offline without accounts using high-density QR codes across iOS and Android.

• 100% Offline Core & Privacy Guarantee
Zero accounts, ads, or cloud speech recording. Your phrases, custom trees, and private logs never leave your device. Optional, strictly opt-in anonymous usability timing collects zero text or audio.
```

### URLs
* **Support URL:** `https://github.com/triton1502oc/Sotto-iOS/issues`
* **Marketing URL:** `https://github.com/triton1502oc/Sotto-iOS`
* **Privacy Policy URL:** `https://github.com/triton1502oc/Sotto-iOS/blob/main/PRIVACY_POLICY.md`

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

### Screenshot Set Organization (App Store Review Compliant)
Both folders contain 5 sequential screens matching App Store Connect review requirements:
1. `01_aac_speech_board.png` – Low-stimulus AAC speech grid with Quick-Speak bar
2. `02_two_way_partner_triage.png` – Caregiver yes/no crisis triage & 180° tabletop partner mode
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

## 4. App Review Notes

When submitting for App Review, provide this note for the reviewer:
```text
Sotto is an assistive communication (AAC) app for autistic and non-verbal individuals. 
- Speech-to-text (Microphone & Speech Recognition) is used solely when the user or communication partner taps the microphone button in the Quick-Speak bar, Partner Mode (Talk tab), or Question Tree Editor to transcribe spoken words into text.
- Text-to-speech uses native AVFoundation AVSpeechSynthesizer.
- App Intents and Siri Shortcuts (Open Emergency Triage, Show Safety Card) provide hands-free and hardware Action Button emergency navigation for users during sensory shutdowns and acute freezes.
- No login or account is required. All data is stored locally on the device in UserDefaults.
- Optional anonymous interaction telemetry is strictly opt-in, disabled by default, and collects zero personal, phrase, or audio data.
```

---

## 5. Apple Accessibility & Inclusivity Editorial Pitch

Submit this pitch to Apple Developer Relations / App Store Editorial under the **Inclusivity & Accessibility** nomination:

### Pitch Summary:
* **App:** Sotto - Assistive AAC Speech
* **Category:** Accessibility, Medical, Utilities
* **Target Audience:** Autistic teens & adults, situational non-speaking users, parents & caregivers navigating meltdowns.

### What Makes Sotto Unique:
1. **Crisis-First Interaction Design**: Traditional AAC apps assume calm, continuous symbol communication. Sotto is purpose-built for the acute verbal shutdown / sensory meltdown crisis loop. The Two-Way HUD with 180° tabletop rotation gives families an immediate, low-demand binary triage tool (`Yes`, `No`, `Not sure`, `Stop`) with zero cognitive pressure.
2. **Adult Neurodivergent Dignity**: Mature typography, high-contrast sensory-calm palettes (Charcoal, OLED Pure Black, Warm Amber, Slate Navy, Soft Parchment), and zero patronizing pediatric cartoon icons.
3. **Deep Apple Ecosystem Integration**: 1-press hardware launch via the iPhone Action Button, Accessibility Back Tap, and Siri Shortcuts using native `AppIntents`.
4. **100% Offline Privacy Guarantee**: Zero cloud accounts, zero ads, zero trackers. Rated "Data Not Collected" on App Privacy labels. Features high-density offline QR deck sharing directly between devices without internet.

