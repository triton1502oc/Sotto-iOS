# Sotto for iOS

**TL;DR**: Sotto (meaning *"under one's breath"* or a soft voice) is an assistive communication iOS app designed for autistic teens and adults, featuring a dignified, low-stimulation UI and one-touch Text-to-Speech (TTS).

This repository is the native iOS (SwiftUI) port of the original [Sotto Android app](https://github.com/triton1502oc/Sotto) with 1:1 feature parity and zero third-party dependencies.

---

## Features

- **Modern Low-Stimulus UI**: Dark/Neutral theme (`#121212` background, `#1E1E1E` surface) with high contrast text (`#E0E0E0`), avoiding visual clutter.
- **Zero-Distraction Layout**: The main communication screen has no administrative clutter, providing a safe, predictable environment.
- **Emergency Bystander Mode**: Dedicated full-width hero card for non-verbal episodes and shutdowns. Features a distinct `🚨 Emergency` badge and a specialized fullscreen view with high-contrast amber styling (`#251E14` / `#FFB74D`) for bystanders, doctors, or first responders.
- **Quick-Speak Bar**: Spontaneous communication bar docked at the bottom with instant speech (`🔊`), fullscreen expansion (`⛶`), and real-time voice dictation (`🎤` via `SFSpeechRecognizer`).
- **Contextual Categories**: Group and filter phrases with low-stimulus filter chips (**All**, **Emergency**, **Needs**, **Social**, **General**).
- **Instant Speech**: Tap any phrase card to speak immediately using `AVSpeechSynthesizer` with automatic language detection (English and Bahasa Indonesia).
- **High-Visibility Display**: Long press any card or tap the fullscreen button on the quick bar to open a full-screen, high-contrast modal for silent communication.
- **Attention Chime & Haptics**: Native two-tone musical chime (D5 at 587.33 Hz for 90ms followed by A5 at 880.00 Hz for 160ms with harmonic overtone and exponential decay) and haptic alert to capture listener attention before speech begins.
- **Customizable Phrase Grid**: Toggle "Edit List" to add new phrases, edit text & categories, delete, and manage phrases.
- **Configurable Voice & Language**: Select app language, fine-tune speech rate (0.5x to 2.0x) and pitch (0.7x to 1.3x) with live "Test Voice" preview.
- **100% Native & Private**: Built entirely using native Apple frameworks (`SwiftUI`, `AVFoundation`, `Speech`). Completely local processing with zero tracking, zero accounts, and 100% offline privacy.

---

## Project Structure

```
Sotto-iOS/
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
│   │   └── SpeechRecognizerService.swift # SFSpeechRecognizer dictation service
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

---

## License
This project is licensed under the Apache License 2.0.
