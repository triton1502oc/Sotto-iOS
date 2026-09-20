# Changelog

### TL;DR
All notable changes to the Sotto (iOS) project will be documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

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
