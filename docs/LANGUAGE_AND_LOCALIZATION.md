# Language & Localization

### TL;DR
- **First Launch**: Default cards are seeded in English or Indonesian based on device locale and saved to local storage (`UserDefaults`).
- **Changing App Language (Settings)**: Changes UI labels and default TTS voice. Existing cards **do not change** to protect user edits, but Sotto auto-detects their language so TTS still pronounces them correctly.
- **Dual-Language Switcher (`EN` ⇄ `ID` on Home)**: Tapping cards while `ID` is active translates English cards into Indonesian offline and speaks Indonesian.

---

## 1. Default Cards (First Launch)

On first run, [`UserDefaultsPhraseRepository`](../Sotto/Data/PhraseRepository.swift) saves default cards to local storage:

| Category | English | Indonesian |
| :--- | :--- | :--- |
| **Safety** (🛡️ full width) | "I cannot speak right now. Please read my screen." | "Saya tidak bisa bicara sekarang. Tolong baca layar saya." |
| **Needs** | 1. "I need a quiet space."<br>2. "Please give me time."<br>3. "I need to leave now." | 1. "Saya butuh tempat tenang."<br>2. "Tolong beri saya waktu."<br>3. "Saya harus pergi sekarang." |
| **Social** | 1. "Yes, please."<br>2. "No, thank you."<br>3. "Thank you." | 1. "Ya, silakan."<br>2. "Tidak, terima kasih."<br>3. "Terima kasih." |
| **Care** | 1. "Are you in pain?"<br>2. "Do you need water or food?"<br>3. "Do you need the restroom?"<br>4. "Are you feeling cold or warm?"<br>5. "Do you want to rest or sleep?" | 1. "Apakah merasa sakit?"<br>2. "Apakah butuh minum atau makan?"<br>3. "Apakah perlu ke kamar mandi?"<br>4. "Apakah merasa dingin atau panas?"<br>5. "Apakah ingin istirahat atau tidur?" |
| **General** | 1. "Hello."<br>2. "Please repeat that." | 1. "Halo."<br>2. "Tolong ulangi." |

> Existing cards are never overwritten on app updates or locale changes. Safety cards can be toggled on/off on the Home screen in Voice & Language Settings.

---

## 2. Switching Language

There are two distinct language features in Sotto:

### A. App Language (Settings → App Language)
- **UI Chrome**: All app text switches language instantly, including:
  - Top Bar action buttons: `[✏️ Edit]` / `[✓ Done]` (English) ➔ `[✏️ Edit]` / `[✓ Selesai]` (Indonesian).
  - Partner Mode (`🤝`) tabs: `Talk` / `Why Finder` ➔ `Bicara` / `Pencari Sebab`.
  - Receptive 4-Card Dock: `Yes`, `No`, `Not Sure`, `Stop` ➔ `Ya`, `Tidak`, `Belum Tahu`, `Stop`.
  - Partner action controls: `Clear`, `Flip`, `Read Aloud` ➔ `Bersihkan`, `Putar`, `Baca Bersuara`.
- **Existing Cards**: Remain in their original language (persisted in `UserDefaults`).
- **TTS Engine**: Default voice switches, but [`LocaleHelper.detectLocale()`](../Sotto/Utils/LocaleHelper.swift) detects English or Indonesian words on existing cards and still speaks them with the appropriate voice.

### B. Dual-Language Switcher (Top Bar `[ EN | ID ]`)
*Enabled via Settings → "Show language switcher on home"*.
- **`EN` Active**: Cards speak in English.
- **`ID` Active**: Tapping an English card translates it on-the-fly to Indonesian offline via Apple Translation or built-in dictionary ([`TranslationHelper`](../Sotto/Services/TranslationHelper.swift)), displays a `🗣️` subtitle, and speaks in Indonesian.
- **Fullscreen**: Long-press any card to choose **Speak (English)** or **Speak (Bahasa Indonesia)**.
- **Quick-Speak Bar**: Translates typed input into the selected language before speaking.

---

## 3. Speech Synthesis & Natural Voice Resolution

Sotto's [`SpeechService`](../Sotto/Services/SpeechService.swift) features an intelligent voice selection and scoring algorithm designed to ensure communication sounds natural, dignified, and clear:

### A. Dignified Voice Scoring & Heuristics
When "Auto" voice is selected, Sotto evaluates all installed voices using structured heuristics:
- **Quality Tier**: Prioritizes `.premium` (+3000 pts) and `.enhanced` (+2000 pts) over compact `.default` (+1000 pts).
- **Novelty Filtering**: Novelty and toy sound-effect voices (e.g. *Albert*, *Bad News*, *Boing*, *Cellos*, *Good News*, *Trinoids*, *Zarvox*) receive a heavy penalty (-5000 pts) and are filtered out of the settings picker to preserve user dignity.
- **Flagship Voice Priority**: Prioritizes Apple's most natural voices:
  - **English**: **Samantha** (`en-US`), **Siri / Ava / Alex** (`en-US`), **Daniel** (`en-GB`), **Karen** (`en-AU`). English "Auto" resolves directly to Samantha.
  - **Indonesian**: **Damayanti** (`id-ID`).
- **Emergency Phone Number Digit Spacing**: Phone numbers are spoken digit-by-digit (`formatDigitsForSpeech`) so the synthesizer reads e.g. *"0 8 1 2"* instead of reading an 11-digit integer as an incomprehensible number.

### B. Installing Apple's Free Neural Voices (iOS / iPadOS)
Apple devices do not install the 500MB+ Enhanced neural models by default. Users can upgrade their voice quality for free:
1. Open **Settings > Accessibility > Spoken Content > Voices**.
2. Tap the desired language (e.g. **English** or **Indonesian**).
3. Select **Samantha** (or **Siri**, **Ava**, **Damayanti**) and tap the cloud download icon (☁️) for **Enhanced** or **Premium**.
4. Sotto automatically detects the enhanced quality voice on its next speech utterance.

---

## 4. Key Files

- [`LocaleHelper.swift`](../Sotto/Utils/LocaleHelper.swift): Locale management and keyword-based language detection.
- [`SpeechService.swift`](../Sotto/Services/SpeechService.swift): Intelligent voice scoring, flagship selection, and phonetics formatting.
- [`PhraseRepository.swift`](../Sotto/Data/PhraseRepository.swift): Persistent storage in `UserDefaults`.
- [`TranslationHelper.swift`](../Sotto/Services/TranslationHelper.swift): Offline translation dictionary and normalization.
- [`MainView.swift`](../Sotto/Views/MainView.swift): TTS routing, top bar toggle, and card actions.
