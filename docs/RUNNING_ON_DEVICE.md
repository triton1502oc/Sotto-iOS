# Running Sotto on a Physical iOS Device (iPhone / iPad)

**TL;DR**: Connect your iPhone or iPad via USB, configure a free personal development team in Xcode, trust your developer certificate on the device, and press `Cmd + R` (or use `xcrun devicectl`) to install and run.

---

### 1. Prerequisites
- A Mac with **Xcode 15.0+** installed.
- An Apple ID (a free personal Apple ID works; a paid Apple Developer account is not required for testing on your own device).
- An iPhone or iPad running **iOS 16.0+** (as configured in `project.yml`).

---

### 2. Connect Your Device & Enable Developer Mode (iOS 16+)
1. Connect your iPhone or iPad to your Mac using a USB cable.
2. If prompted on your device, tap **Trust This Computer** and enter your passcode.
3. On iOS 16 and later, enable **Developer Mode**:
   - On your device, go to **Settings > Privacy & Security**.
   - Scroll to the bottom and tap **Developer Mode**.
   - Toggle **Developer Mode** to **ON**.
   - Restart your device when prompted, then tap **Turn On** and enter your passcode after rebooting.

---

### 3. Configure Signing in Xcode
1. Open the project in Xcode:
   ```bash
   open Sotto.xcodeproj
   ```
2. In the Xcode Project Navigator (left sidebar), select the **Sotto** project root.
3. Select the **Sotto** target under *Targets*.
4. Click on the **Signing & Capabilities** tab.
5. Check **Automatically manage signing**.
6. Under **Team**, select your Personal Team (e.g., *Your Name (Personal Team)*). If you haven't added your Apple ID to Xcode yet:
   - Click **Add Account…**, sign in with your Apple ID, and select your personal team.
7. If needed, update the **Bundle Identifier** to make it unique for your personal team (e.g., `com.yourname.sotto`).

---

### 4. Build and Install via Xcode
1. In the Xcode top toolbar, click on the device selector (next to the scheme `Sotto`) and choose your physical iPhone or iPad.
2. Press **Cmd + R** (or click the **Play** button) to build and install.

---

### 5. CLI Alternative (Command-Line Installation)
You can also build and install directly from the terminal:
```bash
# 1. Build Debug package for iOS devices
xcodebuild -project Sotto.xcodeproj -scheme Sotto \
  -configuration Debug -destination "generic/platform=iOS" \
  -derivedDataPath ./build CODE_SIGNING_ALLOWED=NO

# 2. Find your connected device's UUID
xcrun devicectl list devices

# 3. Install onto physical device
xcrun devicectl device install app --device <DEVICE_UUID> \
  ./build/Build/Products/Debug-iphoneos/Sotto.app

# 4. Launch app on device
xcrun devicectl device process launch --device <DEVICE_UUID> \
  com.amh.sotto
```

---

### 6. Trust Your Developer Certificate on First Launch
If this is your first time deploying an app using your personal Apple ID:
1. When the app finishes installing, iOS will show an *"Untrusted Developer"* alert.
2. On your iPhone or iPad, navigate to:
   **Settings > General > VPN & Device Management**
3. Under **Developer App**, tap your Apple ID.
4. Tap **Trust "[Your Apple ID]"** and confirm.
5. Tap the **Sotto** icon on your home screen to launch!
