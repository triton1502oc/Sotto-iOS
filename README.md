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
- **Unified Caregiver Mode & Why Finder (`👂` / `🤝`)**: Dedicated receptive HUD for caregivers, family members, and medical personnel featuring two integrated modes:
  - **Talk**: Receptive speech-to-text dictation (`🎤 Listen`), card prompt picker, offline TTS read-aloud, and 180° face-to-face screen flip (`🔄 Flip`) for partners sitting across a table.
  - **Why Finder Guided Crisis Tree**: Step-by-step calm yes/no branching tree designed specifically for meltdowns and verbal shutdowns. Navigates physical comfort, sensory input, emotional overwhelm, and environmental friction with a 4-card tactile response dock (`✓ Yes`, `✕ No`, `? Not Sure`, `⏹ Stop`), body part location grid, and 1-5 intensity scale.
- **Private Why Log & 30-Day Trend Insights**: Local-only de-escalation session log with pattern analytics showing category percentage shares, top specific triggers, and peak time-of-day crisis clusters to help families identify environmental stressors.
- **Customizable Question Tree Editor**: Tree customizer dialog allowing families to edit questions, add personalized triggers, reorder with single-step ▲/▼ buttons, dictate via speech recognition (`🎤`), or reset to clinical defaults with one tap.
- **Backup & Restore Format v2**: Granular export/import engine to selectively backup phrases, custom Why trees, and private Why logs into JSON files with merge and replace restore strategies.
- **Multi-Line Quick-Speak Bar & Card Saving**: Spontaneous communication bar docked at the bottom with multi-line text input (1 to 4 lines), instant speech (`🔊`), fullscreen expansion (`⛶`), voice dictation (`🎤`), smart clear toggle (`✕`), and 1-tap card saving (`+`).
- **Contextual Categories & Reordering**: Full custom category management with fine-motor single-step ▲/▼ reordering, protected system safety categories (`Emergency`, `General`), and safe fallback reassignment upon deletion.
- **Instant Speech**: Tap any phrase card to speak immediately using `AVSpeechSynthesizer` with automatic language detection (English and Bahasa Indonesia).
- **High-Visibility Display**: Long press any card or tap the fullscreen button on the quick bar to open a full-screen, high-contrast modal for silent communication.
- **Attention Chime & Haptics**: Native two-tone musical chime (D5 at 587.33 Hz for 90ms followed by A5 at 880.00 Hz for 160ms with harmonic overtone and exponential decay) and haptic alert to capture listener attention before speech begins.
- **Configurable Voice & Language**: Permanent settings gear icon (`⚙️`) to select app language, fine-tune speech rate (0.5x to 2.0x) and pitch (0.7x to 1.3x) with live "Test Voice" preview.
- **Dual-Language Speech & On-Device Translation**: Display cards in one language (e.g. English) while speaking in another (e.g. Indonesian) with a subtle indicator (`🗣️`). Features on-device auto-translation (100% private, zero user text sent to the cloud) and dual-language speak controls in fullscreen view.
- **Privacy-Preserving Telemetry v2 (Opt-In)**: Optional, zero-PII usability telemetry measuring accessibility latency and hesitation to assess product-market fit, complete with category scrubbing (`custom`), payload inspection preview sheet, and a 14-day PMF survey modal.
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
