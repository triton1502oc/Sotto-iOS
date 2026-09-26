# Sotto for iOS

**TL;DR**: Sotto (meaning *"under one's breath"* or a soft voice) is an assistive communication iOS app designed for autistic teens and adults, speech-impaired individuals, and non-speaking users, featuring a dignified, low-stimulation UI and one-touch Text-to-Speech (TTS).

This repository is the native iOS (SwiftUI) port of the original [Sotto Android app](https://github.com/triton1502oc/Sotto) with 1:1 feature parity and zero third-party dependencies.

---

## Who is Sotto For?
- **Autistic Teens & Adults**: A sensory-friendly, mature dark-neutral interface with zero pediatric clutter, designed for routine communication, sensory overload, and verbal shutdowns.
- **Speech-Impaired Individuals**: Accessible one-touch speech synthesis for individuals living with apraxia, dysarthria, ALS, cerebral palsy, vocal chord paralysis, or recovering from a stroke (aphasia).
- **Situational & Temporary Speech Loss**: Anyone experiencing vocal strain, laryngitis, post-surgical recovery, severe fatigue, or needing silent communication in loud, overwhelming environments.

---

## Features

- **Modern Low-Stimulus UI**: Dark/Neutral theme (`#121212` background, `#1E1E1E` surface) with high contrast text (`#E0E0E0`), avoiding visual clutter.
- **Zero-Distraction Layout**: The main communication screen has no administrative clutter, providing a safe, predictable environment.
- **Emergency Bystander Mode**: Dedicated full-width hero card for non-verbal episodes and shutdowns. Features a distinct `🚨 Emergency` badge and a specialized fullscreen view with high-contrast amber styling (`#251E14` / `#FFB74D`) for bystanders, doctors, or first responders.
- **Two-Way Caregiver Receptive Mode (`👂`)**: Dedicated receptive HUD for caregivers, family members, and medical personnel. Includes real-time speech transcription (`🎤 Listen & Read`), offline TTS read aloud (`🔊 Read Aloud`), categorized question prompts (`Care`, `Needs`, `Social`, `Emergency`), and a dignified 4-button rapid response dock (`✓ Yes`, `✕ No`, `🔁 Repeat`, `⏳ Wait`) with instant speech and haptic feedback.
- **180° Face-to-Face Screen Flip**: One-tap display inversion (`🔄 Flip`) in Caregiver mode that rotates the question prompt and response buttons upside down for a partner sitting across a table, while keeping caregiver controls upright.
- **Multi-Line Quick-Speak Bar & Card Saving**: Spontaneous communication bar docked at the bottom with multi-line text input (1 to 4 lines), instant speech (`🔊`), fullscreen expansion (`⛶`), voice dictation (`🎤`), smart clear toggle (`✕`), and 1-tap card saving (`+`).
- **Contextual Categories**: Group and filter phrases with low-stimulus filter chips (**All**, **Emergency**, **Needs**, **Social**, **Care**, **General**).
- **Instant Speech**: Tap any phrase card to speak immediately using `AVSpeechSynthesizer` with automatic language detection (English and Bahasa Indonesia).
- **High-Visibility Display**: Long press any card or tap the fullscreen button on the quick bar to open a full-screen, high-contrast modal for silent communication.
- **Attention Chime & Haptics**: Native two-tone musical chime (D5 at 587.33 Hz for 90ms followed by A5 at 880.00 Hz for 160ms with harmonic overtone and exponential decay) and haptic alert to capture listener attention before speech begins.
- **Customizable Phrase Grid**: Toggle "Edit List" to add new phrases, edit text & categories, delete, and manage phrases.
- **Configurable Voice & Language**: Permanent settings gear icon (`⚙️`) to select app language, fine-tune speech rate (0.5x to 2.0x) and pitch (0.7x to 1.3x) with live "Test Voice" preview.
- **Dual-Language Speech & On-Device Translation**: Display cards in one language (e.g. English) while speaking in another (e.g. Indonesian) with a subtle indicator (`🗣️`). Features on-device auto-translation (100% private, zero user text sent to the cloud) and dual-language speak controls in fullscreen view.
- **100% Native & Private**: Built entirely using native Apple frameworks (`SwiftUI`, `AVFoundation`, `Speech`, `Translation`). Completely local processing with zero tracking, zero accounts, and 100% offline privacy.

---

## Demo Videos

High-definition, synchronized demo videos showcasing Sotto's core features (Quick Speak, Emergency Hero Card, Contextual Categories, Card Reordering, Voice Settings with Attention Chime, and Dual-Language Speech):

- **English Demo**: [`demo/sotto_demo_en.mp4`](demo/sotto_demo_en.mp4) (64s, H.264, 192 kbps AAC audio)
- **Indonesian Demo**: [`demo/sotto_demo_id.mp4`](demo/sotto_demo_id.mp4) (64s, H.264, 192 kbps AAC audio)

For full details on the automated recording pipeline and reproduction instructions, see [demo/README.md](demo/README.md).

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
│   ├── CAREGIVER_GUIDE.md          # User & Caregiver Guide (Two-Way Mode, cards, emergency)
│   ├── CROSS_PLATFORM_WORKFLOW.md  # Android-to-iOS porting guide & checklist
│   ├── LANGUAGE_AND_LOCALIZATION.md# Language models, TTS voice data, and offline translation
│   └── RUNNING_ON_DEVICE.md        # Physical device installation instructions
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
│   │   ├── Phrase.swift            # Phrase & PhraseCategory data models
│   │   └── VoiceSettings.swift     # Speech rate, pitch, voice & chime settings
│   ├── Data/
│   │   ├── PhraseRepository.swift  # UserDefaults persistence & default seed data
│   │   └── VoiceSettingsRepository.swift
│   ├── Services/
│   │   ├── ChimePlayer.swift       # In-memory D5->A5 chime PCM synthesizer & haptics
│   │   ├── SpeechService.swift     # AVSpeechSynthesizer management & rate mapping
│   │   ├── SpeechRecognizerService.swift # SFSpeechRecognizer dictation service
│   │   └── TranslationHelper.swift # Offline phrase dictionary & language normalization
│   ├── Utils/
│   │   └── LocaleHelper.swift      # Language detection & locale helpers
│   ├── Theme/
│   │   └── Theme.swift             # Low-stimulus dark theme palette
│   ├── ViewModels/
│   │   └── MainViewModel.swift     # Reactive state management
│   ├── Views/
│   │   ├── MainView.swift          # Main container screen
│   │   ├── PhraseCardView.swift    # Standard & Emergency card components
│   │   ├── QuickSpeakBarView.swift # Bottom spontaneous communication bar
│   │   ├── FullscreenPhraseModal.swift # High-visibility modal
│   │   ├── PhraseEditModal.swift   # Add/Edit phrase dialog
│   │   ├── TwoWayConversationModal.swift # Caregiver Receptive HUD & 180° flip view
│   │   └── VoiceSettingsModal.swift # Voice & Language configuration sheet
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
- iOS 17.0+ Deployment Target

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

- **Running on Physical Device**: See [docs/RUNNING_ON_DEVICE.md](docs/RUNNING_ON_DEVICE.md) for signing and installation instructions.
- **Contributing & Architecture**: See [CONTRIBUTING.md](CONTRIBUTING.md) for design philosophy, architectural guardrails, and verification rules.
- **Cross-Platform Workflow**: See [docs/CROSS_PLATFORM_WORKFLOW.md](docs/CROSS_PLATFORM_WORKFLOW.md) for the Android-to-iOS porting guide and checklist.
- **AI Agent Guidelines**: See [AGENTS.md](AGENTS.md) for universal flight rules for AI coding assistants.
- **Changelog & Releases**: See [CHANGELOG.md](CHANGELOG.md) for version history.

---

## License
This project is licensed under the GNU General Public License v3.0 (with Apple App Store Exception) - see the [LICENSE](LICENSE) file for details.
