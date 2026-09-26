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
| **Emergency** (🚨 full width) | "I cannot speak right now. Please read my screen." | "Saya tidak bisa bicara sekarang. Tolong baca layar saya." |
| **Needs** | 1. "I need a quiet space."<br>2. "Please give me time."<br>3. "I need to leave now." | 1. "Saya butuh tempat tenang."<br>2. "Tolong beri saya waktu."<br>3. "Saya harus pergi sekarang." |
| **Social** | 1. "Yes, please."<br>2. "No, thank you."<br>3. "Thank you." | 1. "Ya, silakan."<br>2. "Tidak, terima kasih."<br>3. "Terima kasih." |
| **Care** | 1. "Are you in pain?"<br>2. "Do you need water or food?"<br>3. "Do you need the restroom?"<br>4. "Are you feeling cold or warm?"<br>5. "Do you want to rest or sleep?" | 1. "Apakah merasa sakit?"<br>2. "Apakah butuh minum atau makan?"<br>3. "Apakah perlu ke kamar mandi?"<br>4. "Apakah merasa dingin atau panas?"<br>5. "Apakah ingin istirahat atau tidur?" |
| **General** | 1. "Hello."<br>2. "Please repeat that." | 1. "Halo."<br>2. "Tolong ulangi." |

> Existing cards are never overwritten on app updates or locale changes.

---

## 2. Switching Language

There are two distinct language features in Sotto:

### A. App Language (Settings → App Language)
- **UI Chrome**: All app text (buttons, category tabs, hints) switches language.
- **Existing Cards**: Remain in their original language (persisted in `UserDefaults`).
- **TTS Engine**: Default voice switches, but [`LocaleHelper.detectLocale()`](../Sotto/Utils/LocaleHelper.swift) detects English or Indonesian words on existing cards and still speaks them with the appropriate voice.

### B. Dual-Language Switcher (Top Bar `[ EN | ID ]`)
*Enabled via Settings → "Show language switcher on home"*.
- **`EN` Active**: Cards speak in English.
- **`ID` Active**: Tapping an English card translates it on-the-fly to Indonesian offline via Apple Translation or built-in dictionary ([`TranslationHelper`](../Sotto/Services/TranslationHelper.swift)), displays a `🗣️` subtitle, and speaks in Indonesian.
- **Fullscreen**: Long-press any card to choose **Speak (English)** or **Speak (Bahasa Indonesia)**.
- **Quick-Speak Bar**: Translates typed input into the selected language before speaking.

---

## 3. Key Files

- [`LocaleHelper.swift`](../Sotto/Utils/LocaleHelper.swift): Locale management and keyword-based language detection.
- [`PhraseRepository.swift`](../Sotto/Data/PhraseRepository.swift): Persistent storage in `UserDefaults`.
- [`TranslationHelper.swift`](../Sotto/Services/TranslationHelper.swift): Offline translation dictionary and normalization.
- [`MainView.swift`](../Sotto/Views/MainView.swift): TTS routing, top bar toggle, and card actions.
