# Contributing to Sotto (iOS)

### TL;DR
Sotto is an assistive communication (AAC) app designed for autistic teens and adults, speech-impaired individuals, and non-speaking users. We welcome contributions that uphold our dignified, low-stimulation design philosophy, strict SwiftUI architecture, and 1:1 feature parity with Sotto Android.

---

## 1. Mission & Design Philosophy

Sotto (meaning *"under one's breath"* / soft voice) is designed specifically for autistic teens, adults, speech-impaired individuals, and non-speaking users who need clear, dignified text-to-speech support.

* **Dignified & Mature UI**: Zero cartoon clip-art, zero pediatric pastel palettes, and zero nested visual clutter.
* **Low-Stimulus & High-Contrast**: Dark-neutral theme (`#121212` background, `#1E1E1E` surface) with high-contrast text (`#E0E0E0`) and large, fast touch targets.
* **Zero-Distraction Communication**: In active communication mode, administrative actions (add, edit, delete, reorder) are hidden.
* **100% Offline & Private**: Zero accounts, zero tracking SDKs, and zero cloud uploads. All data remains on the device.

---

## 2. Technical Guardrails

* **Platform**: iOS 17.0+ (iPhone and iPad).
* **Language**: 100% Swift (Swift 5.9+).
* **UI Framework**: 100% SwiftUI. Never use legacy Storyboards, UIKit xibs, or unnecessary UIViewController wrappers.
* **Architecture**: Unidirectional data flow / MVVM with `ObservableObject` and reactive state.
* **Audio & Speech**: Native `AVFoundation` (`AVSpeechSynthesizer`, `AVAudioPlayer`) and `Speech` (`SFSpeechRecognizer`). Strictly zero third-party dependencies.
* **Persistence**: Native `UserDefaults` with robust Codable serialization.
* **Project Configuration**: Driven by `project.yml` via `xcodegen generate`. Never manually modify `project.pbxproj`.
* **Cross-Platform Parity**: Sotto development is led by Android (`../Sotto`) and ported to iOS (`Sotto-iOS`) with 1:1 feature parity.

---

## 3. Development Setup & Build Instructions

### Prerequisites
* **macOS 14.0+**
* **Xcode 15.0+**
* **XcodeGen**: Install via Homebrew: `brew install xcodegen`

### Common Commands
* **Regenerate Xcode Project**:
  ```bash
  xcodegen generate
  ```
* **Build App**:
  ```bash
  xcodebuild -project Sotto.xcodeproj -scheme Sotto -destination "generic/platform=iOS Simulator" build
  ```
* **Run Unit Tests**:
  ```bash
  xcodebuild test -project Sotto.xcodeproj -scheme SottoTests -destination "platform=iOS Simulator,name=iPhone 16"
  ```
* **Run on Physical Device**:
  See [docs/RUNNING_ON_DEVICE.md](docs/RUNNING_ON_DEVICE.md) for signing and installation instructions.

---

## 4. Release Process & Guides

* Releases are tracked in [CHANGELOG.md](CHANGELOG.md) and published via GitHub Releases (`gh release create`).
* User and caregiver workflows are documented in [docs/CAREGIVER_GUIDE.md](docs/CAREGIVER_GUIDE.md).
* App Store assets and metadata are documented in [docs/APP_STORE_LISTING.md](docs/APP_STORE_LISTING.md).
* Cross-platform porting guidelines are documented in [docs/CROSS_PLATFORM_WORKFLOW.md](docs/CROSS_PLATFORM_WORKFLOW.md).
* Community standards are defined in our [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

---

## 5. Licensing & Inbound Contributions

Sotto is licensed under the [GNU General Public License v3.0](LICENSE) with an Apple App Store Exception. All contributions submitted to this repository are understood to be licensed under these same terms.

