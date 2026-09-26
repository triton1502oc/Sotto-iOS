# Apple App Store Listing & Submission Guide

### TL;DR
Ready-to-use metadata, descriptions, keywords, screenshot specifications, and privacy nutrition label answers for submitting Sotto to Apple App Store Connect.

---

## 1. App Store Connect Metadata

### App Details
* **App Name:** `Sotto - Assistive AAC Speech` *(29 / 30 characters)*
* **Subtitle:** `Dignified Low-Stimulus AAC` *(26 / 30 characters)*
* **Primary Category:** `Medical` or `Utilities`
* **Secondary Category:** `Productivity`
* **Age Rating:** `4+` (No violence, no objectionable content, no user tracking)

### Promotional Text *(168 / 170 characters)*
```text
Dignified, one-touch AAC speech communication for autistic teens, adults, and speech-impaired users. Low-stimulus dark theme, emergency hero card, and 100% private.
```

### Keywords *(Comma-separated, no spaces after commas, 96 / 100 characters)*
```text
aac,autism,speech,assistive,talk,tts,nonverbal,communication,mute,autistic,emergency,text to speech
```

### Full Description *(Markdown & Plain Text compliant, ~1,950 / 4,000 characters)*
```text
Sotto (meaning "under one's breath" or a soft voice) is an assistive augmentative and alternative communication (AAC) app designed for autistic teens, adults, speech-impaired individuals, and non-speaking users who need clear, dignified, and low-stimulation text-to-speech support.

Unlike typical AAC tools built with pediatric cartoon symbols and complex administrative menus, Sotto provides a calm, mature, and predictable environment built specifically for everyday communication.

KEY FEATURES:

• Modern Low-Stimulus UI
Dark-neutral aesthetic (#121212 background, #1E1E1E surface) with high-contrast text and zero unnecessary visual clutter or distracting animations.

• Zero-Distraction Communication Mode
In normal mode, all editing and administrative buttons are completely hidden. Tap any phrase card to speak immediately using iOS's offline text-to-speech engine.

• Emergency Bystander Mode
A dedicated hero card for verbal shutdowns and non-verbal episodes. Long-press or tap fullscreen to display a high-contrast amber banner explaining non-verbal episodes clearly to bystanders, doctors, or first responders.

• Two-Way Caregiver Receptive Mode
A dedicated receptive interface accessible via the ear icon (👂) allowing caregivers and medical partners to speak or present questions to non-speaking users. Features 180° face-to-face screen flip, read aloud audio for questions, preset question prompts (Care, Needs, Social, Emergency), and a dignified 4-button rapid response dock (Yes, No, Repeat, Wait) with instant voice and haptics.

• Multi-Line Quick-Speak Bar
Speak spontaneous thoughts without altering your phrase board. Features an expandable multi-line text input (1 to 4 lines), one-tap phrase saving to card (+), voice dictation (🎤), and instant fullscreen display.

• Contextual Categories
Organize and filter phrases by situation (Emergency, Needs, Social, Care, General) with clean, subtle filter chips.

• High-Visibility Fullscreen Mode
In noisy, crowded, or overwhelming environments, view any phrase in giant, high-contrast text across your entire screen to silently communicate with others.

• Attention Chime & Haptics
Optionally sound a gentle, two-tone chime (D5 -> A5) and vibration before speaking to politely capture listener attention in noisy spaces.

• Configurable Voice & Speed
Fine-tune your speech output to your comfort. Adjust speech rate and pitch with a live voice preview. Always accessible via the settings gear icon (⚙️).

• Dual-Language Speech & On-Device Auto-Translate
Display cards in one language while speaking in another (e.g., English card text read aloud in Indonesian). Includes on-device auto-translation with zero cloud text transmission and dual-language speak controls in fullscreen view.

• Fully Customizable
Toggle "Edit List" when you want to add new phrases, edit existing text, delete phrases, or assign categories.

• 100% Offline & Private
Zero accounts. Zero tracking. Zero cloud uploads. Your phrases and settings stay entirely on your local device.
```

### URLs
* **Support URL:** `https://github.com/triton1502oc/Sotto-iOS/issues`
* **Marketing URL:** `https://github.com/triton1502oc/Sotto-iOS`
* **Privacy Policy URL:** `https://github.com/triton1502oc/Sotto-iOS/blob/main/PRIVACY_POLICY.md`

---

## 2. Screenshot & Media Requirements

| Device Display | Dimensions | Required / Recommended |
|---|---|---|
| **iPhone 6.9" / 6.7"** (iPhone 16 Pro Max, 15 Pro Max, 14 Pro Max) | 1320 x 2868 px or 1290 x 2796 px | Required |
| **iPhone 6.5"** (iPhone 11 Pro Max, XS Max) | 1242 x 2688 px | Required (if supporting older aspect ratios) |
| **iPad Pro 13" / 12.9"** | 2064 x 2752 px or 2048 x 2732 px | Required if iPad supported |
| **App Icon** | 1024 x 1024 px (PNG, no transparency) | Included in Assets.xcassets |

---

## 3. App Privacy Questionnaire (App Store Connect)

When completing the **App Privacy** section in App Store Connect:

1. **Do you or your third-party partners collect data from this app?**  
   👉 Select **"No, we do not collect data from this app"**.
2. **Resulting Label:** **Data Not Collected**.

---

## 4. App Review Notes

When submitting for App Review, provide this note for the reviewer:
```text
Sotto is an assistive communication (AAC) app for autistic and non-verbal individuals. 
- Speech-to-text (Microphone & Speech Recognition) is used solely when the user taps the microphone button in the Quick-Speak bar or Phrase Editor to dictate a custom phrase.
- Text-to-speech uses native AVFoundation AVSpeechSynthesizer.
- No login or account is required. All data is stored locally in UserDefaults.
```
