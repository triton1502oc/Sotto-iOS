# Privacy Policy for Sotto (iOS)

### TL;DR
Sotto is completely private and operates 100% offline. Sotto does not collect, store, transmit, or share any personal information, usage analytics, or device identifiers.

---

**Last Updated:** October 10, 2026

## 1. Overview
Sotto is an assistive communication (AAC) application designed for autistic individuals, speech-impaired individuals, non-speaking individuals, and anyone needing text-to-speech support. Your privacy, autonomy, and security are fundamental to our design philosophy.

## 2. Information We Do Not Collect
* **No Personal Information:** Sotto does not ask for, access, or store your name, email address, phone number, location, or any personal details.
* **No Speech or Phrase Data Stored by Us:** All phrases, custom messages, and speech output are processed locally on your device. We never record, upload, or transmit what you say or type. 
* **Voice Input (Speech-to-Text):** If you use the microphone feature to dictate phrases in Quick-Speak, Partner Mode, or the Question Tree Editor, Sotto utilizes Apple's native `Speech` framework (`SFSpeechRecognizer`). Sotto itself does not collect, store, or transmit your voice data.
* **Camera Input (QR Code Deck Scanner):** If you use the camera to scan a phrase deck QR code, camera video frames are processed exclusively in real-time local memory via `AVCaptureSession` to decode the QR payload. No photos or video feeds are ever recorded, saved, or uploaded to any server.
* **Offline QR Deck Generation:** Exporting a phrase deck generates a QR code entirely within device memory without contacting any external network or web service.
* **On-Device Translation:** If you use the Auto-Translate feature, translation is performed locally on your device via Apple's native `Translation` framework. All translation processing is executed 100% locally and privately; your text is never sent to external servers or recorded.
* **No Commercial Trackers or Ads:** Sotto contains zero commercial tracking SDKs, no advertising networks, and no third-party marketing frameworks.
* **Optional Opt-In Usability Telemetry:** Sotto includes an optional, strictly opt-in interaction telemetry toggle in Voice & Language Settings. If explicitly turned on by the user, it logs coarse interaction timings and button tap counts to assess product usability and accessibility latency. It collects strictly zero phrases, speech, text, names, or personal identifiers. The exact payload can be reviewed on-screen at any time via "View Shared Data Preview", and the feature is disabled by default.

## 3. Local Device Storage
Any customizations you make—such as adding, editing, or rearranging phrases, custom Why Finder decision trees, private de-escalation logs, or adjusting voice speed, pitch, or color themes—are stored strictly on your local device using iOS's sandboxed app storage (`UserDefaults`). This data never leaves your device and is erased if you uninstall the app.

## 4. Third-Party Services
Sotto does not integrate with any third-party analytics or cloud data services. Speech synthesis is handled directly by Apple's native `AVSpeechSynthesizer`, and on-device translation is executed locally via Apple's `Translation` framework.

## 5. Children's Privacy
Because Sotto collects no personal data whatsoever from any user, it does not collect personal information from children or adults of any age.

## 6. Changes to This Policy
If we make any updates to Sotto's privacy practices, we will update this document accordingly. Since the core mission of Sotto is privacy and dignified communication, the commitment to zero data collection remains permanent.

## 7. Contact
If you have any questions or suggestions regarding this privacy policy, please contact us via our GitHub repository:  
https://github.com/triton1502oc/Sotto-iOS
