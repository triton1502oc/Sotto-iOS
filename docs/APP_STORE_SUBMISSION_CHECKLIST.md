# Apple App Store Submission Checklist & Guide

### TL;DR
Follow this complete step-by-step checklist to configure Apple Developer Portal, App Store Connect, sign and archive the build in Xcode, test via TestFlight, and submit Sotto for App Store Review.

---

## Pre-Flight Checklist (Already Prepared in Codebase)

| Item | Status | Details |
|---|---|---|
| **Privacy Manifest** | ✅ Done | `Sotto/Resources/PrivacyInfo.xcprivacy` with `UserDefaults` reason `CA92.1` and zero data collection |
| **App Store Icon** | ✅ Done | `Sotto/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` (1024x1024, opaque, no alpha) |
| **Export Compliance** | ✅ Done | `ITSAppUsesNonExemptEncryption: false` in `Info.plist` |
| **Code Signing** | ✅ Done | `CODE_SIGN_STYLE: Automatic` configured in `project.yml` |
| **Bundle Identifier** | ✅ Done | `com.amh.sotto` |
| **Deployment Target** | ✅ Done | iOS 16.0+ (iPhone & iPad) |

---

## Step 1: Apple Developer Portal Setup

1. Sign in to [Apple Developer Account](https://developer.apple.com/account).
   > [!IMPORTANT]
   > An active **Apple Developer Program** membership ($99/year) is required to distribute on the App Store or TestFlight.
2. Go to **Certificates, Identifiers & Profiles > Identifiers**.
3. Click the blue **+** button to register a new identifier:
   - Select **App IDs** > Click **Continue**.
   - Select **App** > Click **Continue**.
   - **Description**: `Sotto`
   - **Bundle ID**: Select **Explicit** and enter:
     ```text
     com.amh.sotto
     ```
   - **Capabilities**: No special capabilities need to be checked (Microphone and Speech Recognition use standard system prompts declared in `Info.plist`).
4. Click **Continue** and then **Register**.

---

## Step 2: App Store Connect Setup

1. Sign in to [App Store Connect](https://appstoreconnect.apple.com).
2. Navigate to **Apps** and click the **+** button > **New App**:
   - **Platforms**: `iOS`
   - **Name**: `Sotto - Assistive AAC Speech`
   - **Primary Language**: `English (U.S.)`
   - **Bundle ID**: Select `com.amh.sotto`
   - **SKU**: `sotto-ios-01` (or any internal identifier)
   - **User Access**: `Full Access`
   - Click **Create**.

3. In **App Information** (left sidebar):
   - **Subtitle**: `Dignified Low-Stimulus AAC`
   - **Primary Category**: `Medical` or `Utilities`
   - **Secondary Category**: `Productivity`
   - **Content Rights**: Select "No" (does not contain third-party content).
   - **Age Rating**: Complete the questionnaire (all answers are "None" / "No" -> Result: `4+`).

4. In **Pricing and Availability**:
   - Set price to **Free** ($0.00).
   - Choose availability (All countries or specific territories).

5. In **App Privacy** (left sidebar):
   - Click **Get Started**.
   - Question: *"Do you or your third-party partners collect data from this app?"*
   - Select **"No, we do not collect data from this app"**.
   - Click **Publish**. Resulting label will be **Data Not Collected**.

---

## Step 3: Configure Signing & Archive in Xcode

1. Open `Sotto.xcodeproj` in Xcode:
   ```bash
   open Sotto.xcodeproj
   ```
2. In Xcode, ensure your Apple ID is signed in:
   - Go to **Xcode > Settings > Accounts** (or `Cmd + ,`).
   - If your Apple ID is not listed, click **+** and add it.
3. In the Xcode Project Navigator:
   - Click on the root **Sotto** project.
   - Under **Targets**, select **Sotto**.
   - Select the **Signing & Capabilities** tab.
   - Verify **Automatically manage signing** is checked.
   - Under **Team**, select your Apple Developer Team.
   - Verify **Bundle Identifier** shows `com.amh.sotto`.
4. In the top toolbar device selector:
   - Select **Any iOS Device (arm64)** (do not select a simulator).
5. From the top menu, select:
   **Product > Archive**
6. Wait for Xcode to finish building and archiving the release build.

---

## Step 4: Upload to App Store Connect

1. When the build completes, the **Organizer** window will automatically appear.
2. Select the latest archive and click **Distribute App** (right pane).
3. Select **Custom** > **App Store Connect** (or **App Store Connect** directly).
4. Select **Upload** > Click **Next**.
5. Keep default distribution options checked:
   - *Strip Swift symbols*: Checked
   - *Manage Version and Build Number*: Checked
   - *Upload app's symbols (dSYM)*: Checked
6. Select **Automatically manage signing** > Click **Next**.
7. Review the app summary and click **Upload**.
8. Wait for the upload confirmation (*"App successfully uploaded"*).

---

## Step 5: TestFlight Validation (Recommended)

1. Return to [App Store Connect](https://appstoreconnect.apple.com) > **Apps > Sotto > TestFlight**.
2. Within 5–15 minutes, your uploaded build will finish processing.
   > [!NOTE]
   > If prompted for *Missing Compliance*, click it and confirm that the app uses standard system encryption (`ITSAppUsesNonExemptEncryption` is already in `Info.plist`, so this is usually skipped automatically).
3. Under **Internal Testing**:
   - Click **+** next to Internal Groups.
   - Add your Apple ID as an internal tester.
4. On your iPhone/iPad, open the **TestFlight** app, install Sotto, and verify:
   - App launches cleanly on both iPhone and iPad in Portrait and Landscape orientations.
   - Tap phrase cards to verify text-to-speech with natural voices (Samantha/Siri/Damayanti).
   - Test voice input (microphone & speech recognition permission dialogs).
   - Test Safety bystander card (`🛡️ Safety`), setup wizard, fullscreen mode, and Partner Mode (`🤝`).
   - Test Why Finder guided crisis tree and 4-card response dock (`✓ Yes`, `✕ No`, `? Not Sure`, `⏹ Stop`).
   - Test offline QR Code deck export and camera scanner import.
   - Test sensory appearance themes in Settings.

---

## Step 6: App Store Listing & Review Submission

1. In App Store Connect, go to **iOS App > 1.6.2 Prepare for Submission**.
2. Fill in the listing details using [APP_STORE_LISTING.md](APP_STORE_LISTING.md):
   - **Promotional Text**:
     ```text
     Dignified, one-touch AAC speech communication for autistic teens, adults, and non-speaking users. Low-stimulus themes, Partner Mode, Safety card, and 100% private.
     ```
   - **Description**: Paste the full description from `APP_STORE_LISTING.md`.
   - **Keywords**:
     ```text
     aac,autism,speech,assistive,talk,tts,nonverbal,communication,mute,autistic,safety,text to speech
     ```
   - **Support URL**: `https://github.com/triton1502oc/Sotto-iOS/issues`
   - **Marketing URL**: `https://github.com/triton1502oc/Sotto-iOS`
   - **Privacy Policy URL**: `https://github.com/triton1502oc/Sotto-iOS/blob/main/PRIVACY_POLICY.md`
3. **Screenshots**:
   - Upload at least 1–3 screenshots for **6.9" / 6.7" Display** (iPhone 16 Pro Max / 15 Pro Max: `1290 x 2796` px or `1320 x 2868` px).
   - Upload iPad Pro 13" screenshots (`2064 x 2752` px) for iPad universal support.
4. **Build**:
   - Scroll down to **Build** section and click **+ Select Build**.
   - Choose the uploaded build from Step 4.
5. **App Review Information**:
   - **Sign-In Required**: Unchecked (No login exists).
   - **Contact Information**: Your name, phone number, and email.
   - **Notes**:
     ```text
     Sotto is an assistive communication (AAC) app for autistic and non-verbal individuals. 
     - Speech-to-text (Microphone & Speech Recognition) is used solely when the user or communication partner taps the microphone button in the Quick-Speak bar, Partner Mode (Talk tab), or Question Tree Editor to transcribe spoken words into text.
     - Text-to-speech uses native AVFoundation AVSpeechSynthesizer.
     - No login or account is required. All data is stored locally on the device in UserDefaults.
     - Optional anonymous interaction telemetry is strictly opt-in, disabled by default, and collects zero personal, phrase, or audio data.
     ```
6. Click **Save** in the top right.
7. Click **Add for Review** (or **Submit to App Review**).
8. Once submitted, status will change to **Waiting for Review**. Apple reviews typically take 24 to 48 hours.
