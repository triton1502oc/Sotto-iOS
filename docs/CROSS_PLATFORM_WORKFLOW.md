# Sotto Cross-Platform Development Workflow (Android ➔ iOS)

### TL;DR
Sotto features are developed first in the Android repository (`../Sotto`), and subsequently ported to this iOS repository (`Sotto-iOS`) with 1:1 feature parity. This document outlines the mapping conventions, porting checklist, and App Store readiness guidelines.

---

## 1. Architectural Mapping (Android ➔ iOS)

| Layer / Feature | Android (`Sotto`) | iOS (`Sotto-iOS`) |
|---|---|---|
| **Data Models** | `data/PhraseRepository.kt` (`data class Phrase`) | `Sotto/Models/Phrase.swift` (`struct Phrase`) |
| **Voice Settings** | `data/VoiceSettingsRepository.kt` (`VoiceSettings`) | `Sotto/Models/VoiceSettings.swift` (`VoiceSettings`) |
| **Local Storage** | `SharedPreferencesPhraseRepository.kt` | `Sotto/Data/PhraseRepository.swift` (`UserDefaults`) |
| **Theme / Palette** | `theme/Color.kt` & `Theme.kt` (`#121212`, `#1E1E1E`, `#FFB74D`) | `Sotto/Theme/Theme.swift` (`SottoTheme`) |
| **Attention Chime** | `util/ChimePlayer.kt` (`AudioTrack` 16-bit PCM D5->A5) | `Sotto/Services/ChimePlayer.swift` (`AVAudioPlayer` synthesized WAV) |
| **Text-to-Speech** | `MainActivity.kt` (`android.speech.tts.TextToSpeech`) | `Sotto/Services/SpeechService.swift` (`AVSpeechSynthesizer`) |
| **Voice Dictation** | `RecognizerIntent.ACTION_RECOGNIZE_SPEECH` | `Sotto/Services/SpeechRecognizerService.swift` (`SFSpeechRecognizer`) |
| **Language Detection** | `util/LocaleHelper.kt` (word frequency matching) | `Sotto/Utils/LocaleHelper.swift` (word matching + `NaturalLanguage`) |
| **Main Screen** | `MainActivity.kt` (`SottoApp`, `LazyVerticalGrid`) | `Sotto/Views/MainView.swift` (`LazyVStack` / 2-column chunks) |
| **Phrase Card** | `MainActivity.kt` (`Card`, `isEmergency` hero card) | `Sotto/Views/PhraseCardView.swift` (`PhraseCardView`) |
| **Quick-Speak Bar** | `MainActivity.kt` (`bottomBar`, multiline, save-as-card) | `Sotto/Views/QuickSpeakBarView.swift` (`QuickSpeakBarView`) |
| **Fullscreen Modal** | `MainActivity.kt` (`Dialog`, high-contrast text) | `Sotto/Views/FullscreenPhraseModal.swift` |
| **Add / Edit Dialog**| `MainActivity.kt` (`AlertDialog`, category chips) | `Sotto/Views/PhraseEditModal.swift` |
| **Voice Settings** | `ui/main/VoiceSettingsDialog.kt` | `Sotto/Views/VoiceSettingsModal.swift` |
| **Two-Way Caregiver Mode** | `TwoWayConversationDialog.kt` | `Sotto/Views/TwoWayConversationModal.swift` |
| **Why Finder Crisis Tree** | `WhyFinderSession.kt`, `WhyFinderRepository.kt` | `WhyFinderSession.swift`, `WhyFinderRepository.swift` |
| **Why Tree Editor** | `WhyTreeEditorDialog.kt` | `Sotto/Views/WhyTreeEditorModal.swift` |
| **Private Why Log** | `WhyLogDialog.kt` | `Sotto/Views/WhyLogModal.swift` |
| **Backup & Restore v2** | `PhraseBackupHelper.kt` | `Sotto/Services/PhraseBackupHelper.swift`, `ExportBackupModal.swift`, `ImportBackupModal.swift` |
| **Category Management** | `ManageCategoriesDialog.kt` | `Sotto/Views/ManageCategoriesModal.swift` |
| **Usability Telemetry v2** | `UsabilityTracker.kt` | `Sotto/Services/UsabilityTracker.swift` |
| **14-Day PMF Survey** | `PmfSurveyDialog.kt` | `Sotto/Views/PmfSurveyModal.swift` |
| **180° Screen Flip** | `Modifier.rotate(180f)` | `.rotationEffect(.degrees(180))` |
| **Care Category** | `PhraseCategory.CARE` | `PhraseCategory.care` (`cross.case.fill`) |
| **String Resources** | `res/values/strings.xml`, `values-in/strings.xml` | `PhraseRepository.defaultPhrases()`, `LocaleHelper` |

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
   - Preserve low-stimulus dark aesthetics (`#121212`, `#1E1E1E`, `#FFB74D`).
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
1. **Apple Developer Account**: Enroll in the Apple Developer Program at [developer.apple.com](https://developer.apple.com).
2. **App Store Connect Setup**:
   - Create a new App record in App Store Connect.
   - Copy description, promotional text, keywords, and URLs from [`APP_STORE_LISTING.md`](APP_STORE_LISTING.md).
3. **App Privacy (Nutrition Labels)**:
   - Select **Data Not Collected** as documented in [`PRIVACY_POLICY.md`](../PRIVACY_POLICY.md) and [`APP_STORE_LISTING.md`](APP_STORE_LISTING.md).
4. **Screenshots**:
   - Capture screenshots on iPhone 6.9"/6.7" (e.g. main phrase grid, emergency card, voice settings modal).
5. **Archive & Submit**:
   - In Xcode, select **Product > Archive**, validate, and upload the build to App Store Connect for review.
