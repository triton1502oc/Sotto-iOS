# Changelog

### TL;DR
All notable changes to the Sotto (iOS) project will be documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v1.6.3] - 2026-10-11

### Added
- **App Intents & Hardware Action Button Launch**: Integrated App Intents and `SottoShortcuts` (`EmergencyLaunchManager`) enabling eyes-free, hardware Action Button, iOS Back Tap, and Siri Shortcuts ("Open Emergency Triage", "Show Safety Card") emergency crisis navigation during acute shutdowns and cognitive freezes (#18). Includes privacy-preserving activation telemetry tracking (`shortcut_action_button`).
- **Curated Situational Scenario Decks**: Curated situational phrase decks with scannable offline QR codes for Medical & ER triage, Public Transit navigation, School & Special Education environments, and Dental Care visits in `docs/SCENARIO_DECKS.md` (#19).
- **Synchronized Video Previews & Media Links**: Broadcast-ready 16:9 App Store preview (`sotto_app_store_preview.mp4` / https://youtu.be/Qk76_dPfbko) and 9:16 Shorts/Reels preview (`sotto_vertical_preview.mp4` / https://youtube.com/shorts/7jKnRHIvJv8) featuring neural baritone narration, ambient bed, and Attention Chime across documentation and listings.
- **CI/CD Automation Suite**: Configured GitHub Actions continuous integration (`ios.yml`) and automated Release packaging workflow (`release.yml`) producing release IPA artifacts matching the Android release pipeline.
- **Unified Creative Asset Library**: Standardized App Store Connect screenshots for iPhone Dynamic Island (1206x2622) and iPad 13-inch (2064x2752), Product Page Headers (21:9, 16:9), and Search Result Creatives in 24-bit RGB with an automated generation script (`scripts/build_assets.sh`).

### Changed
- **App Store Optimization & Accessibility Pitch**: Refined App Store Connect metadata, keywords, submission guide, and checklist focusing on caregiver crisis de-escalation, dignity-first AAC, and 100% offline privacy guarantees in `docs/APP_STORE_LISTING.md` and `docs/APP_STORE_SUBMISSION_CHECKLIST.md` (#20).
- **Support & Feedback Links**: Updated Settings feedback and issue reporting links to point directly to Sotto-iOS GitHub issues.

## [v1.6.2] - 2026-10-10

### Added
- **Intelligent Voice Selection & Novelty Filtering**: Intelligent voice ranking algorithm in `SpeechService` prioritizing Apple's natural flagship voices (**Samantha**, **Siri**, **Ava**, **Alex** for English; **Damayanti** for Indonesian). Filters out toy and novelty sound-effect voices (Albert, Bad News, Boing, Cellos, etc.) from the voice selection sheet.
- **Enhanced Neural Voice Guide**: In-app guidance card in Voice & Language Settings explaining how to download Apple's free Enhanced and Premium neural voice models in iOS/iPadOS Accessibility Settings.
- **Instant QR Code Deck Sharing & Scanner**: Offline phrase deck export and camera-based QR code import modal (`QRCodeModal.swift`, `QRScannerModal.swift`) supporting compressed Base64 payloads (`SOTTO:v1:...`) for seamless sharing across iOS and Android devices without internet or accounts (#13).
- **Standard Multi-Card Safety Category**: Deprecated the rigid emergency contact setup wizard (`EmergencySetupWizardModal`) and removed tap interception (#16). Safety is now a standard, first-class card category allowing users to create, edit, and maintain multiple custom safety phrases (e.g. shutdown notifications, sensory space requests, or contact details) directly through the standard editor.
- **Settings Streamlining**: Removed the "Configure Emergency Contact Card" button from Voice & Language Settings, retaining only the clean "Show Safety cards on Home" toggle in 1:1 parity with Android (#16).
- **Natural Digit-by-Digit Phone Number Speech**: Automatic digit separation (`formatDigitsForSpeech`) ensuring emergency contact numbers are spoken aloud digit-by-digit rather than mispronounced as enormous integers.
- **VoiceOver Accessibility & Dynamic Type**: Comprehensive semantic accessibility labels, hints, and custom actions across phrase cards and controls (#10), paired with Dynamic Type font scaling for low-vision AAC users (#9).
- **Persistent Emergency Quick-Action**: Persistent safety action access across tabs and views (#11).

### Security & Reliability
- **100% On-Device Speech Recognition**: Enforced `recognitionRequest.requiresOnDeviceRecognition = true` in `SpeechRecognizerService.swift` guaranteeing complete offline transcription privacy (#1).
- **Privacy Manifest Telemetry Declaration**: Explicitly declared product interaction telemetry under `NSPrivacyCollectedDataTypes` in `PrivacyInfo.xcprivacy` with Analytics purpose per Apple App Store Review guidelines (#2).
- **Encrypted Storage for Health Logs & Temporary File Cleanup**: Migrated Why Finder logs to Application Support with `completeFileProtection` encryption at rest, and automated temporary file cleanup after export sharing (#7).
- **Main Thread Safety in Speech Services**: Enforced `@MainActor` isolation and verified asynchronous state dispatches in `SpeechRecognizerService` (#5).
- **Microphone & Audio Lifecycle Management**: Added `.onDisappear` handlers across modals to reliably release microphone and audio engine resources on dismissal (#4).
- **Cumulative Dictation Duplication Fix**: Resolved transcription text duplication via baseline tracking in `MainViewModel` and edit dialogs (#3).
- **Apple HIG Touch Target Compliance**: Enforced 44x44 pt minimum touch targets across all category chips, buttons, and card controls (#8).
- **Clean 64-bit Device Capabilities**: Replaced legacy `armv7` requirement with `arm64` in `Info.plist` (#6).
- **Partner Mode Flipped Orientation Lock**: Suppressed auto-rotation during 180° face-to-face screen flip in Partner Mode to prevent accidental inversion (#14).
- **Asynchronous QR Code Rendering**: Offloaded QR image bitmap generation to background tasks to prevent main-thread UI stalling on older devices.

## [v1.6.1] - 2026-10-10

### Added
- **Sensory-Minded Color Themes**: Curated sensory-friendly color palettes accessible from Voice & Language Settings (`Appearance` section) to accommodate neurodivergent needs, photophobia, and astigmatism halation while upholding WCAG 2.1 AAA contrast: **Charcoal** (default low-stimulus dark neutral), **OLED Pure Black** (maximum contrast and power efficiency), **Warm Amber / Low Strain** (low blue light dark sepia), **Slate Navy** (calm focus), and **Soft Parchment** (anti-halation muted daylight). Automatic dynamic light/dark status bar and window styling based on theme. Safety semantics remain invariant and distinct across all themes.
- **Dignified Safety System & Personal Safety Card Templates**: Reframed the emergency system into a dignified, low-stimulus **Safety** system (`🛡️ Safety`). Added personal safety phrase templates for caregiver phone numbers and general neighborhood/locality orientation to protect user residential privacy. Added a "Show Safety Cards on Home" toggle in Settings to allow freeing 100% of the Home grid for everyday communication.
- **iPad Universal Support & Adaptive Grid**: Full universal iPad optimization with responsive dynamic grid layouts (up to 4 columns on large screens), navigation stack preservation on all modal sheets, and full orientation support (Portrait, Upside-Down, Landscape Left/Right) compliant with Apple App Store guidelines.
- **Two-Way HUD Streamlined Triage**: Streamlined caregiver triage controls in Two-Way Receptive Mode HUD with tactile 4-card response dock (`Yes`, `No`, `Not Sure`, `Stop`).
- **Telemetry Schema v3 & Tap Event Aggregation**: Optimized privacy-preserving usability tracking with schema v3, aggregating routine tap events to minimize payload size and device overhead, alongside privacy-preserving intent tracking and Settings adoption snapshots.

### Changed
- **Partner Mode Icon Unification (`🤝`)**: Aligned top bar caregiver receptive mode icon from ear (`👂`) to partner handshake (`🤝`) matching Android and Why Finder clinical triage conventions.
- **Localized Edit Button**: Streamlined top bar action button label to `[✏️ Edit]` / `[✓ Done]` (and Indonesian `[✏️ Edit]` / `[✓ Selesai]`) replacing `[✏️ Edit List]`.
- **Category Bar Streamlining**: Removed the redundant Safety filter chip from the main screen's horizontal category bar to reduce visual clutter, while keeping Safety manageable in Edit Mode.
- **Default Emergency Consolidation Migration**: Automatically consolidates legacy emergency cards into the single privacy-safe emergency template on update.

## [v1.6.0] - 2026-10-07

### Added
- **Why Finder Guided Crisis Tree**: Step-by-step calm yes/no branching tree designed specifically for meltdowns and verbal shutdowns. Guides caregivers and individuals through physical discomfort, sensory overload, emotional overwhelm, and routine friction with large binary touch targets and zero open-ended cognitive demands.
- **Private Why Log & 30-Day Trend Insights**: Local-only crisis logging engine that tracks resolved de-escalation sessions. Automatically generates 30-day pattern insights showing category percentage shares, top specific triggers, and peak time-of-day crisis clusters to help families and therapists identify environmental stressors.
- **Customizable Question Tree Editor**: Dedicated crisis tree customizer dialog allowing families to edit questions, add personalized triggers, create custom crisis areas, or reset to clinical defaults with one tap. Supports voice dictation (`🎤`), fine-motor single-step ▲/▼ reordering, and interaction type selection (`Yes/No`, `Body Part Grid`, `Intensity Scale 1-5`).
- **Backup & Restore Format v2**: Enhanced backup engine with granular checkboxes to selectively export phrases, Why trees, and Why logs. Enables safe sharing of custom trees with therapists or schools while keeping private crisis logs strictly excluded by default. Supports both Merge and Replace restore strategies.
- **Anonymous Usability Telemetry v2 for Product-Market Fit**: Enhanced privacy-preserving usability monitoring engine featuring anonymous app-assigned install IDs, coarse temporal bucketing (day-of-week and hour window), optional user role selection (`Caregiver`, `Self`, `Professional`), category privacy scrubber (`custom`), 500-event local buffer, and a transparent payload preview sheet in Voice Settings.
- **14-Day In-App Product-Market Fit Survey**: Low-stimulus Sean Ellis PMF survey prompted after 14 days and at least 5 active days for opted-in users during calm idle states to evaluate product value and core benefits.

### Changed
- **Unified Caregiver Mode**: Merged Why Finder and Two-Way Receptive Mode into a single cohesive Caregiver HUD featuring **Talk** (receptive speech-to-text dictation, card prompt picker, 180° screen flip) and **Why Finder** (crisis branching tree with 4-card response dock, interactive body part grid, and 1-5 intensity scale).
- **Semantic Low-Stimulus Color Tokens**: Centralized all colors into semantic tokens in `Theme.swift` with low-stimulus palettes, dark neutral surfaces, and high contrast compliance.
- **Category Management**: Full custom category support with single-step ▲/▼ reordering, protected system categories (`Emergency`, `General`), safe fallback reassignment to `General` upon deletion, and dynamic category pickers across all views.

## [v1.5.7] - 2026-09-26

### Added
- **Two-Way Caregiver Receptive Mode**: Dedicated receptive HUD accessible via the ear icon (`👂`) in the top bar, allowing caregivers, medical professionals, and communication partners to speak or present questions to non-speaking users.
- **180° Face-to-Face Screen Flip**: One-tap screen inversion (`🔄 Flip`) that turns the question display and response dock upside down for conversation partners sitting across a table, while keeping caregiver controls upright.
- **Read Aloud for Questions**: Added a `🔊 Read Aloud` button in caregiver mode to vocalize the displayed question text via offline TTS for users with visual fatigue or eyes closed.
- **Categorized Question Bank**: Quick question picker with category filter chips (`Care`, `All`, `Needs`, `Social`, `Emergency`, `General`) for standard care and comfort checks.
- **Dignified 4-Button Rapid Response**: High-contrast, tactile response dock with four dignified answers (`Yes`, `No`, `Repeat`, `Wait`), each triggering instant TTS speech, visual badge confirmation, and subtle haptic feedback.
- **Care Category & Phrases**: Added new `Care` category filter chip with 5 default care phrases in English and Indonesian (*"Are you in pain?"*, *"Do you need water or food?"*, etc.) with automated migration for existing user libraries.
- **Streamlined Midline Top Bar**: Unified top app bar featuring Two-Way Receptive Mode (`👂`), permanent Voice & Language Settings (`⚙️`), and clean rounded `[✏️ Edit List]` action button centered on the exact horizontal midline with zero layout shifting.
- **Caregiver & User Guide**: Added comprehensive documentation in `docs/CAREGIVER_GUIDE.md` covering daily AAC cards, emergency hero mode, Quick-Speak, and caregiver two-way interactions.
- **Community Standards**: Added Contributor Covenant `CODE_OF_CONDUCT.md` v2.1, `SECURITY.md`, pull request template, and issue templates.

## [v1.5.6] - 2026-09-24

### Added
- **Multi-Line Quick-Speak View**: Typing sentences in the Quick-Speak bar now expands vertically (up to 4 lines), keeping the full sentence visible and easy to edit.
- **Save as Card from Quick-Speak**: Added a `+` button in the Quick-Speak bar to save spontaneous phrases directly into your phrase board with one tap.
- **Smart Dictation / Clear Toggle**: The input bar now shows voice dictation (`🎤`) when empty and smoothly switches to clear (`✕`) while typing, giving more space for text.

## [v1.5.5] - 2026-09-22

### Added
- **Language Code Normalization**: Added normalization for 3-letter ISO-639-2 language codes (e.g. `eng`, `ind`) returned by system TTS engines, mapping them properly to standard ISO-639-1 tags.
- **Localization Guide**: Added `docs/LANGUAGE_AND_LOCALIZATION.md` documenting card seeding, app locale switching, and offline translation.

## [v1.5.4] - 2026-09-21

### Added
- **Settings Gear Icon**: Added permanently accessible settings gear icon (`⚙️`) to the top bar for instant access to Voice & Language Settings.

### Changed
- **Documentation Overhaul**: Streamlined and condensed project documentation, contributing guidelines, and agent instructions.

## [v1.5.3] - 2026-09-20

### Fixed
- **Quick-Speak & Speech Cards in Dual-Language Mode**: On-demand auto-translation for Quick-Speak and untranslated speech cards in dual-language mode when secondary language is active.
- **Legacy Storage Sanitization**: Sanitized legacy `"auto"` entries in `spokenText` to `nil`.

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
