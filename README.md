# Sotto for iOS

<p align="center">
  <img src="assets/sotto_ios_banner.png" alt="Sotto for iOS Banner" width="100%" />
</p>

<p align="center">
  🎬 <b>Video Demo:</b> 
  <a href="https://youtu.be/Qk76_dPfbko">YouTube (Master Preview)</a> •
  <a href="https://youtube.com/shorts/7jKnRHIvJv8">YouTube Shorts</a>
</p>

**TL;DR**: Sotto (*"under one's breath"*) is a calm yes/no tool for caregivers to reach autistic teens & adults in meltdowns and verbal shutdowns, paired with a dignified, low-stimulation AAC speech board for self-expression.

This repository is the native iOS (SwiftUI) port of [Sotto Android](https://github.com/triton1502oc/Sotto) with 1:1 feature parity and zero third-party dependencies.

---

## Origin & The Dual Mode Truth

> *"Built by a father in Singapore for his two autistic sons (22 & 15) who can speak but not always. During meltdown I operate Sotto on MY phone, they tap Yes/No to pinpoint — issue resolved."*

Sotto was created out of real family experience. When sensory overload strikes, operating a phone, reading complex choices, or processing multi-step menus is impossible.

We use Sotto in two distinct modes:

* **MODE 1 — DAILY (He holds his phone):**  
  Self-operated dignified AAC for complex information, noisy spaces, or unfamiliar people. The individual opens Sotto themselves and taps phrase cards (**Needs**, **Social**, **Care**, **General**) or types in the Quick-Speak Bar. 1-tap speech, long-press for giant fullscreen text. Universal iPhone & iPad.
* **MODE 2 — MELTDOWN (You hold YOUR phone):**  
  Caregiver-operated on the caregiver's device. During acute sensory meltdowns or verbal shutdowns, operating a phone is too difficult. The caregiver opens Sotto, enters Partner Mode, flips the phone 180° (`🔄`) to show giant text, and the individual taps **Yes / No / Wait / Repeat** (or **Not sure / Stop**). Direct binary choice pinpoints the problem without navigating a complex tree.

> **Medical Disclaimer:** Sotto is not a medical device and does not provide medical advice, diagnosis, or treatment. It is an assistive communication tool.

---

## Target Audience
- **Parents, Siblings, Family, Caregivers & Allies**: Reaching loved ones during verbal shutdowns, cognitive freezes, and meltdowns with immediate 1-tap binary check-ins; discovering hidden root causes post-crisis.
- **Autistic Teens & Adults**: Dignified self-advocacy and daily communication with high-contrast, low-stimulation phrase cards and giant fullscreen text.
- **Individuals with Unclear, Fatigued, or Non-Speaking Speech**: Accessible one-touch speech for motor apraxia, dysarthria, cerebral palsy, ALS, stroke recovery (aphasia), quiet/strained voices, or situational speech loss.

---

## Key Features

### 1. Direct Yes/No Crisis Navigation & Post-Crisis Explorer (Caregiver Mode)
- **Two-Way Partner Mode & 180° Flip (`🤝`)**: Immediate crisis support for acute meltdowns and verbal shutdowns. Caregivers speak naturally or pick preset questions, flip the display 180° on a table, and the individual responds with one tap on huge 80pt+ targets (`Yes`, `No`, `Wait`, `Repeat` / `Not sure`, `Stop`) with instant voice confirmation. Zero cognitive load.
- **Why Finder Post-Crisis Explorer (`🧭`)**: When distress triggers are unknown, Why Finder provides a gentle, post-crisis binary discovery tree to systematically uncover hidden physical discomfort (with body map locator), sensory overload, emotional fatigue, or routine disruptions without demanding open-ended answers.
- **Private Pattern Log & 30-Day Trends**: Automatically logs resolved crisis events locally in private app storage. Highlights top 30-day root-cause patterns and peak time-of-day clusters to help families identify recurring environmental stressors.
- **Customizable Inquiry Tree (`🌳`)**: Personalize questions and areas with voice dictation (`🎤`), sequence reordering, and one-tap defaults reset.

### 2. Dignified Self-Expression (AAC Phrase Board)
- **Low-Stimulus UI & Sensory Color Themes**: Curated sensory-friendly color palettes accessible from Voice & Language Settings (`Appearance` section) to accommodate neurodivergent needs, photophobia, and astigmatism halation while upholding WCAG 2.1 AAA contrast: **Charcoal** (default low-stimulus dark neutral), **OLED Pure Black** (maximum contrast and power efficiency), **Warm Amber / Low Strain** (low blue light dark sepia), **Slate Navy** (calm focus), and **Soft Parchment** (anti-halation muted daylight).
- **Universal iPad & iPhone Support**: Full universal iPad and iPhone support with adaptive multi-column grid layouts, smooth rotation support across all orientations (Portrait, Landscape, Upside-Down), and zero visual clutter.
- **Zero-Distraction Mode**: The main communication screen has no administrative clutter, providing a safe, predictable environment. Administrative actions (add, edit, delete, reorder) remain hidden during communication.
- **Safety Bystander Card**: Dedicated full-width hero card for non-verbal episodes and shutdowns. Features a distinct `🛡️ Safety` badge, digit-by-digit phone number TTS formatting so emergency numbers are read naturally, and a specialized fullscreen view with high-contrast amber styling (`#251E14` / `#FFB74D`) for bystanders, doctors, or first responders.
- **Multi-Line Quick-Speak Bar & Card Saving**: Spontaneous communication bar docked at the bottom with multi-line text input (1 to 4 lines), instant speech (`🔊`), fullscreen expansion (`⛶`), voice dictation (`🎤`), smart clear toggle (`✕`), and 1-tap card saving (`+`).
- **Contextual Categories & Reordering**: Full custom category management with fine-motor single-step ▲/▼ reordering, protected system safety categories (**Safety**, **Needs**, **Social**, **Care**, **General**), and safe fallback reassignment upon deletion.
- **High-Visibility Giant Fullscreen**: Long-press any card or tap the fullscreen button on the quick bar to open a full-screen, high-contrast modal for silent communication in loud spaces.
- **Attention Chime & Haptics**: Native two-tone musical chime (D5 at 587.33 Hz for 90ms followed by A5 at 880.00 Hz for 160ms with harmonic overtone and exponential decay) and haptic alert to capture listener attention before speech begins.
- **Dignified & Natural Speech Engine**: Tap any phrase card to speak immediately using `AVSpeechSynthesizer` with automatic language detection (English and Bahasa Indonesia). Features intelligent voice scoring prioritizing natural flagship voices (Samantha, Siri, Ava, Damayanti), novelty voice filtering, and in-app guidance for downloading Apple's free Enhanced and Premium neural voices.
- **Dual-Language Speech & On-Device Translation**: Display cards in one language (e.g. English) while speaking in another (e.g. Indonesian) with a subtle indicator (`🗣️`). Features on-device auto-translation (100% private, zero user text sent to the cloud) and dual-language speak controls in fullscreen view.

### 3. Privacy & Offline Guarantee
- **100% Offline Core**: Zero cloud accounts, zero ads, and zero third-party tracking SDKs. Audio, phrases, Why Finder trees, and Why logs stay strictly on-device.
- **Instant Offline QR Code Deck Sharing**: Share and import phrase decks instantaneously offline using high-density QR codes (`SOTTO:v1:...`) and an integrated camera scanner between iOS and Android devices—zero accounts, cloud, or AirDrop required.
- **Backup & Restore Format v2**: Granular export/import engine to selectively backup phrases, custom Why trees, and private Why logs into JSON files with merge and replace restore strategies. Easily export a customized tree to a therapist or teacher without sharing private crisis notes.
- **Privacy-Preserving Telemetry v2/v3 (Opt-In)**: Optional, strictly opt-in (default OFF) anonymous interaction telemetry measuring accessibility latency and hesitation to assess product-market fit, complete with category scrubbing (`custom`), payload inspection preview sheet, and a 14-day PMF survey modal (zero text, audio, or phrase hashes collected).

---

## Demo Videos

High-definition, synchronized demo videos showcasing Sotto's flagship assistive communication and crisis navigation features on iOS:

- **App Store Preview (Master)**: [`demo/sotto_app_store_preview.mp4`](demo/sotto_app_store_preview.mp4) (60s, 1920×1080 Landscape, Neural Baritone + Andrew + Ambient Bed + Chime) — [Watch on YouTube](https://youtu.be/Qk76_dPfbko)
- **Shorts / Reels / TikTok (Vertical)**: [`demo/sotto_vertical_preview.mp4`](demo/sotto_vertical_preview.mp4) (60s, 1080×1920 Portrait 9:16) — [Watch on YouTube Shorts](https://youtube.com/shorts/7jKnRHIvJv8)
- **English Simulator Demo**: [`demo/sotto_demo_en.mp4`](demo/sotto_demo_en.mp4) (~64s, 1206×2622 Portrait, Samantha & Damayanti)
- **Indonesian Simulator Demo**: [`demo/sotto_demo_id.mp4`](demo/sotto_demo_id.mp4) (~64s, 1206×2622 Portrait, Damayanti & Samantha)

For full details on the automated motion generator and reproduction instructions, see [demo/README.md](demo/README.md).

---

## Project Structure

```
Sotto-iOS/
├── CODE_OF_CONDUCT.md              # Contributor Covenant Code of Conduct v2.1
├── SECURITY.md                     # Vulnerability disclosure & offline privacy policy
├── AGENTS.md                       # Universal AI agent guidelines & flight rules
├── CHANGELOG.md                    # Project release notes & version history
├── CONTRIBUTING.md                 # Design philosophy, architecture, & contribution guide
├── demo/                           # Synchronized demo videos & pipeline documentation
│   ├── README.md                   # Video specs & reproduction instructions
│   ├── sotto_demo_en.mp4           # English demo video
│   └── sotto_demo_id.mp4           # Indonesian demo video
├── docs/                           # Documentation and publishing guides
│   ├── APP_STORE_LISTING.md        # App Store Connect metadata & review notes
│   ├── APP_STORE_SUBMISSION_CHECKLIST.md # Step-by-step App Store publishing checklist
│   ├── CAREGIVER_GUIDE.md          # User & Caregiver Guide (Two-Way Mode, cards, emergency)
│   ├── CROSS_PLATFORM_WORKFLOW.md  # Android-to-iOS porting guide & checklist
│   ├── LANGUAGE_AND_LOCALIZATION.md# Language models, TTS voice data, and offline translation
│   ├── RUNNING_ON_DEVICE.md        # Physical device installation instructions
│   └── SCENARIO_DECKS.md           # Curated situational phrase packs & scannable QR codes
├── scripts/                        # Automation & recording pipeline scripts
│   ├── record_demo_en.sh           # Automated English screen recording & muxing
│   ├── record_demo_id.sh           # Automated Indonesian screen recording & muxing
│   ├── generate_audio.py           # Audio synthesis & Attention Chime generator (EN)
│   ├── generate_audio_id.py        # Audio synthesis & Attention Chime generator (ID)
│   ├── mux_audio.py                # Timeline audio-video muxer (EN)
│   └── mux_audio_id.py             # Timeline audio-video muxer (ID)
├── Sotto.xcodeproj                 # Xcode project bundle (generated via XcodeGen)
├── project.yml                     # XcodeGen specification
├── Sotto/
│   ├── SottoApp.swift              # Main SwiftUI App entry point
│   ├── Models/
│   │   ├── BackupData.swift        # Backup & restore v2 serialization models
│   │   ├── Phrase.swift            # Phrase & PhraseCategory data models
│   │   ├── VoiceSettings.swift     # Speech rate, pitch, telemetry & role settings
│   │   └── WhyFinder.swift         # Why Finder tree, questions, and log models
│   ├── Data/
│   │   ├── PhraseRepository.swift  # UserDefaults persistence & default seed data
│   │   ├── VoiceSettingsRepository.swift # Settings, install ID & active day tracking
│   │   └── WhyFinderRepository.swift # Why tree & private offline session logs
│   ├── Services/
│   │   ├── ChimePlayer.swift       # In-memory D5->A5 chime PCM synthesizer & haptics
│   │   ├── PhraseBackupHelper.swift # Backup v2 exporter, importer & log merger
│   │   ├── SpeechService.swift     # AVSpeechSynthesizer management & rate mapping
│   │   ├── SpeechRecognizerService.swift # SFSpeechRecognizer dictation service
│   │   ├── TranslationHelper.swift # Offline phrase dictionary & language normalization
│   │   └── UsabilityTracker.swift  # Privacy-preserving usability telemetry v2
│   ├── Utils/
│   │   └── LocaleHelper.swift      # Language detection & locale helpers
│   ├── Theme/
│   │   └── Theme.swift             # Centralized low-stimulus dark theme palette
│   ├── ViewModels/
│   │   ├── MainViewModel.swift     # Reactive state management
│   │   └── WhyFinderSession.swift  # Why Finder crisis branching state machine
│   ├── Views/
│   │   ├── ExportBackupModal.swift # Backup v2 export dialog with checkboxes
│   │   ├── FullscreenPhraseModal.swift # High-visibility modal
│   │   ├── ImportBackupModal.swift # Backup v2 import review & merge/replace dialog
│   │   ├── MainView.swift          # Main container screen
│   │   ├── ManageCategoriesModal.swift # Category manager with single-step reordering
│   │   ├── PhraseCardView.swift    # Standard & Emergency card components
│   │   ├── PhraseEditModal.swift   # Add/Edit phrase dialog
│   │   ├── PmfSurveyModal.swift    # 14-day low-stimulus PMF survey dialog
│   │   ├── QuickSpeakBarView.swift # Bottom spontaneous communication bar
│   │   ├── TwoWayConversationModal.swift # Unified Caregiver HUD (Talk & Why Finder)
│   │   ├── VoiceSettingsModal.swift # Voice & Language configuration sheet
│   │   ├── WhyLogModal.swift       # Private Why Log & 30-day pattern insights
│   │   └── WhyTreeEditorModal.swift# Question Tree customizer dialog
│   └── Resources/
│       ├── Info.plist              # Privacy descriptions & configuration
│       └── Assets.xcassets/        # AppIcon & AccentColor assets
└── SottoTests/
    └── SottoTests.swift            # Unit tests for models, persistence, and detection
```

---

## Building and Running

### Requirements
- macOS 14.0+
- Xcode 15.0+
- iOS 16.0+ Deployment Target (iPhone & iPad)

### Steps
1. Clone this repository:
   ```bash
   git clone https://github.com/triton1502oc/Sotto-iOS.git
   cd Sotto-iOS
   ```
2. (Optional) Regenerate Xcode project using [XcodeGen](https://github.com/yonaskolb/XcodeGen):
   ```bash
   xcodegen generate
   ```
3. Open `Sotto.xcodeproj` in Xcode:
   ```bash
   open Sotto.xcodeproj
   ```
4. Select the `Sotto` scheme and an iOS Simulator or connected physical device.
5. Press `Cmd + R` to build and run.

## Documentation & Development

- **Caregiver & User Guide**: See [docs/CAREGIVER_GUIDE.md](docs/CAREGIVER_GUIDE.md) for Two-Way Mode, phrase cards, and emergency protocols.
- **Language & Localization**: See [docs/LANGUAGE_AND_LOCALIZATION.md](docs/LANGUAGE_AND_LOCALIZATION.md) for TTS voices, audio tuning, and offline translation.
- **Running on Physical Device**: See [docs/RUNNING_ON_DEVICE.md](docs/RUNNING_ON_DEVICE.md) for signing and installation instructions.
- **Curated Scenario Decks**: See [docs/SCENARIO_DECKS.md](docs/SCENARIO_DECKS.md) for scannable QR codes and printable phrase packs (Medical, Transit, School, Dental).
- **Contributing & Architecture**: See [CONTRIBUTING.md](CONTRIBUTING.md) for design philosophy, architectural guardrails, and verification rules.
- **Cross-Platform Workflow**: See [docs/CROSS_PLATFORM_WORKFLOW.md](docs/CROSS_PLATFORM_WORKFLOW.md) for the Android-to-iOS porting guide and checklist.
- **AI Agent Guidelines**: See [AGENTS.md](AGENTS.md) for universal flight rules for AI coding assistants.
- **Changelog & Releases**: See [CHANGELOG.md](CHANGELOG.md) for version history.
- **Android Reference App**: See [Sotto Android](https://github.com/triton1502oc/Sotto).

---

## License
This project is licensed under the GNU General Public License v3.0 (with Apple App Store Exception) - see the [LICENSE](LICENSE) file for details.
