# Running Sotto on a Physical iOS Device (iPhone / iPad)

**TL;DR**: Connect your iPhone via USB, configure a free personal development team in Xcode, trust your developer certificate on the device, and press `Cmd + R` to install and run.

---

### 1. Prerequisites
- A Mac with **Xcode 15.0+** installed.
- An Apple ID (a free personal Apple ID works; a paid Apple Developer account is not required for testing on your own device).
- An iPhone or iPad running **iOS 17.0+** (or the target version configured in `project.yml`).

---

### 2. Connect Your Device & Enable Developer Mode (iOS 16+)
1. Connect your iPhone to your Mac using a USB-to-Lightning or USB-C cable.
2. If prompted on your iPhone, tap **Trust This Computer** and enter your passcode.
3. On iOS 16 and later, enable **Developer Mode**:
   - On your iPhone, go to **Settings > Privacy & Security**.
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

### 4. Build and Install
1. In the Xcode top toolbar, click on the device selector (next to the scheme `Sotto`) and choose your physical iPhone.
2. Press **Cmd + R** (or click the **Play** button) to build and install.

---

### 5. Trust Your Developer Certificate on First Launch
If this is your first time deploying an app using your personal Apple ID:
1. When the app finishes installing, iOS will show an *"Untrusted Developer"* alert.
2. On your iPhone, navigate to:
   **Settings > General > VPN & Device Management**
3. Under **Developer App**, tap your Apple ID.
4. Tap **Trust "[Your Apple ID]"** and confirm.
5. Tap the **Sotto** icon on your iPhone home screen to launch!
