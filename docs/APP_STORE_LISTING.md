# Apple App Store Listing & Submission Guide

### TL;DR
Ready-to-use metadata, descriptions, keywords, screenshot specifications, and privacy nutrition label answers for submitting Sotto to Apple App Store Connect.

---

## 1. App Store Connect Metadata

### App Details
* **App Name:** `Sotto - Assistive AAC Speech` *(29 / 30 characters)*
* **Subtitle:** `Calm Crisis Triage & Adult AAC` *(30 / 30 characters)*
* **Primary Category:** `Medical` or `Utilities`
* **Secondary Category:** `Productivity`
* **Age Rating:** `4+` (No violence, no objectionable content, no user tracking)

### Promotional Text *(159 / 170 characters)*
```text
Calm yes/no crisis triage for caregivers reaching autistic loved ones in shutdowns, paired with a dignified low-stimulus AAC speech board & Action Button launch.
```

### Keywords *(Comma-separated, no spaces after commas, 97 / 100 characters)*
```text
shutdown,meltdown,deescalation,sensory,mutism,nonverbal,crisis,triage,aphasia,overload,aac,autism,speech
```

### Full Description *(Markdown & Plain Text compliant, ~3,400 / 4,000 characters)*
```text
Sotto is a calm yes/no crisis navigation tool for caregivers, parents, and therapists to connect with autistic teens and adults during sensory overload, meltdowns, and verbal shutdowns — paired with a dignified, low-stimulation AAC speech board for daily self-expression and unclear speech support.

Created by a father of two autistic sons (ages 22 and 15), Sotto is built around a simple reality: during a meltdown or verbal shutdown, processing complex questions or speaking is exhausting. Sotto bridges this divide with gentle binary choices, speech clarity support, zero open-ended demands, and instant hardware Action Button launch.

FOR CAREGIVERS, FAMILIES & THERAPISTS:

• Two-Way Speak HUD & 180° Tabletop Flip (Immediate Emergency Triage)
During acute sensory overload or verbal shutdowns, processing complex questions or branching trees worsens distress. Caregivers can speak naturally or pick an urgent prompt, flip the iPad or iPhone 180° face-to-face on a table, and let their loved one tap giant, dignified response targets (Yes, No, Not sure, Stop) with instant voice confirmation. Zero cognitive load.

• 1-Press Hardware Action Button & Siri Shortcuts (Instant Emergency Access)
During an acute shutdown or motor freeze, navigating screen menus is impossible. Users and caregivers can map the physical iPhone Action Button, iOS Accessibility Back Tap (double-tap back of phone), or Siri Shortcuts ("Open Sotto Emergency") to immediately launch crisis triage or the emergency safety card without looking.

• Why Finder (Guided Root-Cause Discovery Tree)
When the source of distress is unknown, Why Finder provides a gentle, step-by-step yes/no branching tree to systematically uncover hidden physical pain (with body part & intensity locator), sensory overload, emotional fatigue, or routine disruption without open-ended interrogation.

• Private On-Device Why Log & Pattern Trends
Resolved crisis sessions are automatically logged 100% locally on your device. Review 30-day patterns to identify frequent environmental triggers, recurring peak hours, and actionable interventions. Never shared or uploaded to the cloud.

• Customizable Why Tree & Safe Sharing
Adapt questions and areas to your loved one's specific triggers using voice dictation and reordering. Easily export and share customized trees with teachers or speech therapists while keeping private crisis logs strictly excluded.

FOR NON-SPEAKING & UNCLEAR VOICES (DIGNIFIED SELF-EXPRESSION):

• Mature, Dignified Voice for Unclear or Fatigued Speech
Whether completely non-verbal, navigating an autistic shutdown, or speaking with quiet, slurred, or dysarthric speech that listeners struggle to understand, Sotto provides a crisp, adult text-to-speech voice and high-contrast cards—free of childish cartoons and patronizing symbols.

• Safety & Bystander Hero Card
A prominent high-contrast banner for non-verbal episodes, local contacts, or medical personnel. Show fullscreen directly to bystanders or first responders with digit-by-digit emergency phone number TTS read aloud.

• Sensory-Minded Color Themes
Curated sensory-friendly color palettes designed to accommodate neurodivergent needs, photophobia, and astigmatism halation while upholding WCAG 2.1 AAA contrast: Charcoal (default low-stimulus dark neutral), OLED Pure Black, Warm Amber / Low Strain, Slate Navy, and Soft Parchment.

• Universal iPad & iPhone Support
Adaptive responsive grid layouts designed for both iPhone and iPad in all orientations (Portrait, Landscape, Upside-Down), with multi-column support and zero layout shifts.

• Quick-Speak Bar & Voice Dictation
Type spontaneous thoughts with auto-expanding multi-line text (1 to 4 lines), one-tap speech, voice dictation, and one-touch card creation.

• High-Visibility Giant Fullscreen
Display any phrase across the entire display in giant text to silently communicate in loud or crowded environments.

• Contextual Categories & Custom Boards
Filter phrases by situation (Safety, Needs, Social, Care, General) or create custom categories with fine-motor single-step reordering.

• Attention Chime & Haptics
Optionally sound a gentle, two-tone chime (D5 -> A5) and vibration before speaking to politely capture listener attention in noisy spaces.

• Natural Speech Engine
Intelligently prioritizes natural flagship voices (such as Apple's Samantha, Siri, Ava, and Damayanti) while filtering out novelty robotic sound effects. Adjust speech rate and pitch with live voice preview.

• Instant Offline QR Code Deck Sharing
Exchange entire communication decks between caregivers, therapists, and users completely offline without internet or cloud accounts using high-density QR codes and camera scanning across iOS and Android.

• Dual-Language Speech & On-Device Auto-Translate
Display cards in one language while speaking in another (e.g., English text read aloud in Indonesian) using 100% offline on-device translation.

• 100% Offline Core & Privacy Guarantee
Zero accounts. Zero ads. Zero cloud speech recording. Your phrases, custom trees, and private logs never leave your phone. Optional, strictly opt-in anonymous usability timing to help diagnose accessibility friction (zero text or speech collected).
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
| **iPad Pro 13" / 12.9"** | 2064 x 2752 px or 2048 x 2732 px | Required for iPad universal support |
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
- Speech-to-text (Microphone & Speech Recognition) is used solely when the user or communication partner taps the microphone button in the Quick-Speak bar, Partner Mode (Talk tab), or Question Tree Editor to transcribe spoken words into text.
- Text-to-speech uses native AVFoundation AVSpeechSynthesizer.
- App Intents and Siri Shortcuts (Open Emergency Triage, Show Safety Card) provide hands-free and hardware Action Button emergency navigation for users during sensory shutdowns and acute freezes.
- No login or account is required. All data is stored locally on the device in UserDefaults.
- Optional anonymous interaction telemetry is strictly opt-in, disabled by default, and collects zero personal, phrase, or audio data.
```

---

## 5. Apple Accessibility & Inclusivity Editorial Pitch

Submit this pitch to Apple Developer Relations / App Store Editorial under the **Inclusivity & Accessibility** nomination:

### Pitch Summary:
* **App:** Sotto - Assistive AAC Speech
* **Category:** Accessibility, Medical, Utilities
* **Target Audience:** Autistic teens & adults, situational non-speaking users, parents & caregivers navigating meltdowns.

### What Makes Sotto Unique:
1. **Crisis-First Interaction Design**: Traditional AAC apps assume calm, continuous symbol communication. Sotto is purpose-built for the acute verbal shutdown / sensory meltdown crisis loop. The Two-Way HUD with 180° tabletop rotation gives families an immediate, low-demand binary triage tool (`Yes`, `No`, `Not sure`, `Stop`) with zero cognitive pressure.
2. **Adult Neurodivergent Dignity**: Mature typography, high-contrast sensory-calm palettes (Charcoal, OLED Pure Black, Warm Amber, Slate Navy, Soft Parchment), and zero patronizing pediatric cartoon icons.
3. **Deep Apple Ecosystem Integration**: 1-press hardware launch via the iPhone Action Button, Accessibility Back Tap, and Siri Shortcuts using native `AppIntents`.
4. **100% Offline Privacy Guarantee**: Zero cloud accounts, zero ads, zero trackers. Rated "Data Not Collected" on App Privacy labels. Features high-density offline QR deck sharing directly between devices without internet.

