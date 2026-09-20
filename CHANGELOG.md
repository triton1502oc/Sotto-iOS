# Changelog

### TL;DR
All notable changes to the Sotto (iOS) project will be documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [v1.5.2] - 2026-09-20

### Changed
- **Relicense to GNU GPLv3 with Apple App Store Exception**: Updated license to GNU General Public License v3.0 with Apple App Store Exception granting permission to convey via Apple App Store.
- **Single-Language UI & Behavior Simplification**: Completely suppressed and hid all dual-language UI elements and alternate speech playback when "Dual-Language Speech" / "Show language switcher" is disabled in Voice Settings (the default).
- **Card Grid & Emergency Hero**: Hid `🗣️ [spokenText]` indicator row when switcher is off.
- **Card Tap (Read-Aloud)**: Guaranteed cards speak only primary text in primary language when dual-language is disabled, even if alternate spoken text was previously saved.
- **Fullscreen Modal**: Streamlined fullscreen view to display only primary text with a single large `[ Speak Aloud ]` button when dual-language is off.
- **Add / Edit Phrase Dialog**: Hid alternate spoken text section, auto-translate button, and secondary voice input when dual-language is off.

## [v1.5.1] - 2026-09-20

### Fixed
- **Translation Resilience & Defensive Shields**: Wrapped translation and language model handling in defensive error boundaries with graceful fallback to built-in offline AAC phrase dictionary.

### Added
- **Language Model Guidance & Status in Voice Settings**: Informative model status and offline translation indicators under Dual-Language Speech settings.
- **Download Progress & Offline Feedback**: Clear status indicators ("Translating…") and actionable offline error messages.

## [v1.5.0] - 2026-09-20

### Added
- **Dual-Language Card Read-Aloud**: Cards can now display in one language (e.g., English) while reading aloud in another (e.g., Indonesian) with a subtle muted visual indicator (`🗣️`).
- **On-Device Auto-Translate (Apple Translation)**: Instant one-tap translation from card text to secondary language using Apple's native Translation framework with zero user text data transmission.
- **Fullscreen Dual-Language Speech**: Fullscreen card view now provides dedicated speak buttons for both primary and secondary languages with dynamic TTS voice switching.
- **Top Bar Language Switcher**: Optional quick toggle pill (`[ EN | ID ]`) on the home screen to switch the active speech language across cards (configurable in Voice Settings).
- **Secondary Language Settings**: Easily configure preferred secondary speech language in Voice Settings.

## [v1.0.0] - 2026-09-20

### Added
- **Initial Native iOS Port**: Complete 1:1 feature parity port of Sotto from Android (v1.3.5) to iOS using Swift 5.9 and SwiftUI.
- **Modern Low-Stimulus UI**: ASD-friendly dark-neutral theme (`#121212` background, `#1E1E1E` surface) with high-contrast text and zero visual clutter.
- **Emergency Hero Card**: Dedicated full-width card with high-contrast amber banner (`#FFB74D`) for non-verbal episodes, verbal shutdowns, and bystander explanation.
- **Quick-Speak Bar**: Spontaneous communication bar docked at the bottom with speech-to-text voice dictation (`SFSpeechRecognizer`), instant speech (`AVSpeechSynthesizer`), and fullscreen expansion.
- **Attention Chime & Haptics**: Synthesized two-tone chime (D5 -> A5 PCM audio) and haptic feedback before speech playback.
- **Offline & Private**: Zero accounts, zero tracking SDKs, zero cloud uploads. 100% local processing via `UserDefaults`.
- **XcodeGen Integration**: Deterministic Xcode project generation via `project.yml`.
- **Documentation**: Added [CONTRIBUTING.md](CONTRIBUTING.md), [AGENTS.md](AGENTS.md), and comprehensive guides in `docs/`.

### Assets
- `Sotto-v1.0.0.ipa`: Release package for iOS sideloading (AltStore, SideStore, Sideloadly).
