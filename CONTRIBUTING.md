# Contributing to Sotto (iOS)

### TL;DR
Sotto is an assistive communication (AAC) app designed for autistic teens and adults, speech-impaired individuals, and non-speaking users. We welcome contributions that uphold our dignified, low-stimulation design philosophy, strict SwiftUI architecture, and 1:1 feature parity with Sotto Android.

---

## 1. Mission & Design Philosophy

Sotto was created by a father to navigate overwhelming communication breakdowns and meltdowns with his autistic sons (ages 22 and 15). When sensory overload strikes, speaking, reading long sentences, or processing complex questions becomes exhausting or impossible.

- **Primary Mission (Crisis Navigation for Caregivers & Families)**: Provide parents, siblings, family members, caregivers, therapists, and educators with an immediate two-way receptive triage HUD and low-cognitive-load yes/no inquiry to reach loved ones during meltdowns and shutdowns without escalating distress.
- **Secondary Purpose (Dignified Voice for Non-Speaking & Unclear Speech)**: Provide non-speaking individuals, those with unclear or dysfluent speech, and anyone navigating verbal fatigue with a clean, mature text-to-speech board and spontaneous quick-speak bar—free of pediatric cartoons, patronizing symbols, and visual clutter.
- **Dignified & Mature UI**: Zero cartoon clip-art, zero pediatric pastel palettes, and zero nested visual clutter.
- **Low-Stimulus & High-Contrast**: Dark-neutral theme (`#121212` background, `#1E1E1E` surface) with high-contrast text (`#E0E0E0`), curated sensory palettes, and large, fast touch targets.
- **Zero-Distraction Communication**: In active communication mode, administrative actions (add, edit, delete, reorder) remain hidden.
- **100% Offline Core & Privacy-First**: Zero accounts, zero tracking SDKs, and zero cloud uploads. All data remains on the device. Strictly opt-in anonymous interaction telemetry (zero text or speech collected).

---

## 2. Technical Guardrails

* **Platform**: iOS 16.0+ (iPhone and iPad).
* **Language**: 100% Swift (Swift 5.9+).
* **UI Framework**: 100% SwiftUI. Never use legacy Storyboards, UIKit xibs, or unnecessary UIViewController wrappers.
* **Architecture**: Unidirectional data flow / MVVM with `ObservableObject` and reactive state.
* **Audio & Speech**: Native `AVFoundation` (`AVSpeechSynthesizer`, `AVAudioPlayer`) and `Speech` (`SFSpeechRecognizer`). Strictly zero third-party dependencies.
* **Persistence**: Native `UserDefaults` with robust Codable serialization.
* **Project Configuration**: Driven by `project.yml` via `xcodegen generate`. Never manually modify `project.pbxproj`.
* **Cross-Platform Parity**: Sotto development is led by Android (`../Sotto`) and ported to iOS (`Sotto-iOS`) with 1:1 feature parity.
* **Code Standards**: Emphasize simple, concise, and secure Swift code with zero regressions. Prioritize readable Swift idioms over unnecessary abstractions, ensure 100% backwards compatibility for saved user phrases, and preserve offline privacy.
* **Telemetry for New Features**: Every newly added user-facing feature or configurable capability MUST include corresponding privacy-preserving, opt-in telemetry via `UsabilityTracker` (e.g., activation marker, anonymous usage count, or state snapshot) while strictly upholding 100% opt-in, zero-PII guarantees.

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

* **Pre-Release Verification & Device Testing (MANDATORY)**:
  - Regenerate the project (`xcodegen generate`), verify Swift compilation/tests, and install/test the release build on a physical device or simulator before tagging.
  - **AI Agent Rule**: AI agents assisting with a release **must explicitly ask and remind the user to test the release build on a physical device or simulator** before creating the release tag.
* **Version Sync & Doc Audit**:
  - Before publishing any release or version bump, run `python3 scripts/sync_release_docs.py --bump <version> --build <build>` (as needed) and `python3 scripts/sync_release_docs.py --check` to verify cross-document version parity, deployment targets, and documentation integrity.
* **Documentation, Changelog & Issue Milestone Tracking**:
  - Associate planned issues and bug fixes with the target release milestone in GitHub (e.g. `gh issue edit <id> --milestone "v<version>"`), and close the milestone once the release is published.
  - When updating or closing an unassigned issue (`gh issue edit <id>`), always assign it to yourself (`--add-assignee "@me"`).
  - Update [CHANGELOG.md](CHANGELOG.md) under the new version header: check the previous release format via `gh release view` and commit diff via `git log <prev>..<current>`, and link closed issues (e.g. `([#2](...))`).
* **Git Commit, Tag & Automated Release**:
  - Commit release preparations using the standard release chore format: `git commit -m "chore(release): prepare v<version>"`.
  - Push `main` and the `v<version>` tag to trigger `.github/workflows/release.yml` (or publish via `gh release create`).
  - Automated continuous integration also runs on pull requests and pushes to `main` via `.github/workflows/ios.yml` (Gitleaks security scanning, documentation verification, XcodeGen generation, unit tests, and IPA artifact packaging).
* **Reference Guides**:
  - User and caregiver workflows: [docs/CAREGIVER_GUIDE.md](docs/CAREGIVER_GUIDE.md).
  - App Store assets and metadata: [docs/APP_STORE_LISTING.md](docs/APP_STORE_LISTING.md).
  - Cross-platform porting guidelines: [docs/CROSS_PLATFORM_WORKFLOW.md](docs/CROSS_PLATFORM_WORKFLOW.md).
  - Community standards: [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

---

## 5. Licensing & Inbound Contributions

Sotto is licensed under the [GNU General Public License v3.0](LICENSE) with an Apple App Store Exception. All contributions submitted to this repository are understood to be licensed under these same terms.
