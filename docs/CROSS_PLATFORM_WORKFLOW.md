# Sotto Cross-Platform Development Workflow (Android ➔ iOS)

### TL;DR
Sotto features are developed first in the Android repository (`../Sotto`), and subsequently ported to this iOS repository (`Sotto-iOS`) with 1:1 feature parity. This document outlines the mapping conventions, porting checklist, and App Store readiness guidelines.

---

## 1. Architectural Mapping (Android ➔ iOS)

| Layer / Feature | Android (`Sotto`) | iOS (`Sotto-iOS`) |
|---|---|---|
| **Data Models** | `model/Phrase.kt` (`data class Phrase`) | `Sotto/Models/Phrase.swift` (`struct Phrase`) |
| **Voice Settings** | `data/VoiceSettingsRepository.kt` (`VoiceSettings`) | `Sotto/Models/VoiceSettings.swift` (`VoiceSettings`) |
| **Local Storage** | `SharedPreferencesPhraseRepository.kt` | `Sotto/Data/PhraseRepository.swift` (`UserDefaults`) |
| **Theme / Palette** | `theme/Color.kt` & `Theme.kt` (5 sensory palettes) | `Sotto/Theme/Theme.swift` (`SottoTheme`, 5 sensory palettes) |
| **Attention Chime** | `util/ChimePlayer.kt` (`AudioTrack` 16-bit PCM D5->A5) | `Sotto/Services/ChimePlayer.swift` (`AVAudioPlayer` synthesized WAV) |
| **Text-to-Speech** | `MainActivity.kt` (`android.speech.tts.TextToSpeech`) | `Sotto/Services/SpeechService.swift` (`AVSpeechSynthesizer`) |
| **Voice Dictation** | `RecognizerIntent.ACTION_RECOGNIZE_SPEECH` | `Sotto/Services/SpeechRecognizerService.swift` (`SFSpeechRecognizer`) |
| **Language Detection** | `util/LocaleHelper.kt` (word frequency matching) | `Sotto/Utils/LocaleHelper.swift` (word matching + `NaturalLanguage`) |
| **Main Screen** | `MainActivity.kt` (`SottoApp`, `LazyVerticalGrid`) | `Sotto/Views/MainView.swift` (Adaptive 2–6 column adaptive grid, iPad support) |
| **Modular Main Views** | `SottoApp.kt` sub-composables | `Sotto/Views/MainSubViews.swift` (top bar, category chips, cards) |
| **Phrase Card** | `MainActivity.kt` (`Card`, `isEmergency` hero card) | `Sotto/Views/PhraseCardView.swift` (`PhraseCardView`, Safety banner) |
| **Quick-Speak Bar** | `MainActivity.kt` (`bottomBar`, multiline, save-as-card) | `Sotto/Views/QuickSpeakBarView.swift` (`QuickSpeakBarView`) |
| **Fullscreen Modal** | `MainActivity.kt` (`Dialog`, high-contrast text) | `Sotto/Views/FullscreenPhraseModal.swift` |
| **Add / Edit Dialog**| `MainActivity.kt` (`AlertDialog`, category chips) | `Sotto/Views/PhraseEditModal.swift` |
| **Voice Settings** | `ui/main/VoiceSettingsDialog.kt` | `Sotto/Views/VoiceSettingsModal.swift` |
| **Partner Mode & Why Finder (🤝)** | `ui/conversation/TwoWayConversationDialog.kt` | `Sotto/Views/TwoWayConversationModal.swift` (Talk & Why Finder) |
| **Why Finder Crisis Tree** | `WhyFinderSession.kt`, `WhyFinderRepository.kt` | `WhyFinderSession.swift`, `WhyFinderRepository.swift` |
| **Why Tree Editor** | `WhyTreeEditorDialog.kt` | `Sotto/Views/WhyTreeEditorModal.swift` |
| **Private Why Log** | `WhyLogDialog.kt` | `Sotto/Views/WhyLogModal.swift` |
| **Backup & Restore v2** | `PhraseBackupHelper.kt` | `Sotto/Services/PhraseBackupHelper.swift`, `ExportBackupModal.swift`, `ImportBackupModal.swift` |
| **Category Management** | `ManageCategoriesDialog.kt` | `Sotto/Views/ManageCategoriesModal.swift` |
| **QR Code Sharing** | `QrShareDialog.kt`, `QrScanActivity.kt` | `Sotto/Views/QRCodeModal.swift`, `QRScannerModal.swift` |
| **Emergency Safety Setup** | `EmergencySafetySetupDialog.kt` | `Sotto/Views/EmergencySafetySetupModal.swift` |
| **Welcome Onboarding** | `WelcomeOnboardingDialog.kt` | `Sotto/Views/WelcomeOnboardingModal.swift` |
| **Vector Icons** | `SottoIcon.kt` | `Sotto/Theme/SottoIcon.swift` (low-stimulus SF Symbols) |
| **Quick Shortcuts / App Intents** | `EmergencyTileService.kt` | `Sotto/Services/SottoShortcuts.swift` (App Intents & Siri) |
| **Voice Scoring & Quality** | `TtsEngineHelper.kt` | `Sotto/Services/SpeechService.swift` (flagship heuristic scoring) |
| **Usability Telemetry v3** | `UsabilityTracker.kt` | `Sotto/Services/UsabilityTracker.swift` (tap event aggregation) |
| **14-Day PMF Survey** | `PmfSurveyDialog.kt` | `Sotto/Views/PmfSurveyModal.swift` |
| **180° Screen Flip** | `Modifier.rotate(180f)` | `.rotationEffect(.degrees(180))` |
| **Care Category** | `PhraseCategory.CARE` | `PhraseCategory.care` (`cross.case.fill`) |
| **Safety Category** | `PhraseCategory.EMERGENCY` / Safety | `PhraseCategory.emergency` (`shield.fill`) |
| **CI/CD Workflows** | `.github/workflows/android.yml`, `release.yml` | `.github/workflows/ios.yml`, `release.yml` |

### Platform Implementation Divergences
- **TTS Readiness**: Android requires asynchronous TextToSpeech engine initialization (`ttsReady`), whereas iOS `AVSpeechSynthesizer` initializes synchronously upon instantiation; iOS does not require an asynchronous readiness state or initializing banner.
- **Role Preference Storage**: Android stores user role via dedicated SharedPreferences keys (`getUserRole` / `setUserRole`), whereas iOS persists user role within the unified `VoiceSettings` model (`sotto_voice_prefs`).
- **Category Identifiers**: Android defines static string constants (`Phrase.CATEGORY_*`), whereas iOS utilizes a strongly typed `PhraseCategory` struct/enum with Set-based membership lookups.

---

## 2. Feature Porting Checklist

When a new feature or modification is made in the Android codebase:

1. **Review Android Changes**:
   - Inspect the commits and diffs in `../Sotto`.
   - Identify changes to data schemas, default phrases, UI components, or audio behaviors.
2. **Update Core Models & Storage**:
   - If the `Phrase` or `VoiceSettings` schema changes, update `Phrase.swift` and `VoiceSettings.swift` with backward-compatible Codable decoders.
   - Update `PhraseRepository.swift` if default phrase seeds or migrations are modified.
3. **Update Audio & Speech Services**:
   - Ensure TTS rate/pitch scaling or chime parameters remain acoustically identical.
4. **Update SwiftUI Views**:
   - Apply the corresponding UI updates to the relevant SwiftUI views in `Sotto/Views/`.
   - Preserve low-stimulus dark aesthetics (`#121212`, `#1E1E1E`, `#FFB74D`) and sensory theme tokens.
5. **Regenerate Xcode Project**:
   - If any new files or targets were created, run:
     ```bash
     xcodegen generate
     ```
6. **Verify & Test**:
   - Verify Swift syntax with `swiftc $(find Sotto -name "*.swift") -parse`.
   - Run unit tests in `SottoTests/SottoTests.swift`.
7. **Document & Commit**:
   - Update `README.md`, `APP_STORE_LISTING.md`, or `PRIVACY_POLICY.md` if user-facing behavior or permissions changed.
   - Commit changes with clear cross-references to the Android feature commit.

---

## 3. App Store Publishing Path

When preparing for release on the Apple App Store:
1. **Target Compatibility**: Configured for **iOS 16.0+** supporting both iPhone and iPad in `project.yml`.
2. **Apple Developer Account**: Enroll in the Apple Developer Program at [developer.apple.com](https://developer.apple.com).
3. **App Store Connect Setup**:
   - Create a new App record in App Store Connect.
   - Copy description, promotional text, keywords, and URLs from [`APP_STORE_LISTING.md`](APP_STORE_LISTING.md).
   - Verify pre-flight criteria in [`APP_STORE_SUBMISSION_CHECKLIST.md`](APP_STORE_SUBMISSION_CHECKLIST.md).
4. **App Privacy (Nutrition Labels)**:
   - Select **Data Not Collected** as documented in [`PRIVACY_POLICY.md`](../PRIVACY_POLICY.md) and [`APP_STORE_LISTING.md`](APP_STORE_LISTING.md).
5. **Screenshots**:
   - Capture screenshots on iPhone 6.9"/6.7" and iPad 13"/12.9" (main phrase grid, safety card, voice settings modal, partner HUD, Why Finder).
6. **Archive & Submit**:
   - In Xcode, select **Product > Archive**, validate, and upload the build to App Store Connect for review.
