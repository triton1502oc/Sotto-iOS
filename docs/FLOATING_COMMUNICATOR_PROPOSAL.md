# Floating Communicator Parity Strategy (iOS Alternative to Android PiP)

### TL;DR
While Android 8.0+ permits arbitrary Compose views to render inside floating system Picture-in-Picture (PiP) windows (`com.amh.sotto.ui.pip.PipCommunicatorScreen`), Apple's `AVPictureInPictureController` strictly prohibits non-video UI and will fail App Store Guideline 2.5.2 if abused with blank video streams. We recommend implementing **Interactive Live Activities & Dynamic Island** (`ActivityKit` with `LiveActivityIntent`, iOS 16.1+) as the primary iOS floating communicator, supplemented by **App Shortcuts** (Action Button / Siri) and **ControlWidget** (iOS 18+). The system remains 100% offline with zero PII and incorporates opt-in telemetry via `floating_communicator_used`.

---

## 1. Problem Statement & Platform Reality

In Sotto Android (`triton1502oc/Sotto#45`), non-speaking users navigating external applications (e.g. Google Maps, YouTube, web browsers) can maintain a continuous voice through an overlay Picture-in-Picture window containing high-contrast crisis response buttons (`Yes`, `No`, `Wait`).

On iOS, standard applications cannot draw floating overlays above other applications. An architectural alternative is required that achieves:
1. **Low Friction ($\le 2$ taps)**: Rapid access to vital crisis affirmations (`Yes`, `No`, `Wait`, `Need Help`) from any app context.
2. **100% Offline Privacy**: Guaranteed zero network requests, local on-device `AVSpeechSynthesizer`, and zero storage of spoken phrases in shared widget storage.
3. **App Store Guideline Compliance**: Strict adherence to Apple Human Interface Guidelines and App Review Guidelines (Guidelines 2.5.2 and 4.0).
4. **Backward Compatibility**: Deployment target is iOS 16.0+, precluding solutions exclusive to iOS 18 without graceful degradation.

---

## 2. Evaluation of iOS Architecture Alternatives

| Architecture Alternative | Minimum iOS Version | Pros | Cons | Verdict |
| :--- | :--- | :--- | :--- | :--- |
| **A. Dummy Video Canvas PiP** (`AVPictureInPictureController`) | iOS 14.0+ | Floating moveable overlay resembling Android PiP. | Rejection under App Store Guideline 2.5.2 (misuse of video background mode). Severe battery drain. | **Rejected** |
| **B. App Shortcuts & Siri** (`AppIntents` / `AppShortcutsProvider`) | iOS 16.0+ | Works hands-free; mappable to iPhone Action Button and Back Tap. | High cognitive load for non-speaking users during sensory meltdowns. | **Secondary / Complementary** |
| **C. Control Center & Lock Screen Controls** (`ControlWidget`) | iOS 18.0+ | Instant pull-down access from top-right corner over any app. | Requires iOS 18.0+ (excludes iOS 16–17 users). Limited to single-action buttons. | **Phase 2 Enhancement** |
| **D. Interactive Live Activities & Dynamic Island** (`ActivityKit`) | iOS 16.1+ | Persistent glanceable surface on Lock Screen & Dynamic Island; interactive buttons without opening app; 100% offline. | Auto-dismisses after 8–12 hours of inactivity; requires explicit session start. | **Recommended Primary** |

---

## 3. Recommended Architectural Design: Interactive Live Activity

### 3.1 Overview
When the user or caregiver activates **"Floating Communicator"** in Sotto Settings or when entering crisis navigation, Sotto starts an ongoing `Activity<FloatingCommunicatorAttributes>`.

The Live Activity projects interactive controls into two system surfaces:
1. **Dynamic Island** (iPhone 14 Pro, iPhone 15, iPhone 16+):
   - **Compact View**: Displays battery-efficient Sotto speech bubble status.
   - **Expanded View (Long Press)**: Immediate access to `Yes`, `No`, `Wait` buttons that trigger local text-to-speech.
2. **Lock Screen & StandBy Surface** (All iPhones on iOS 16.1+):
   - Persistent high-contrast 4-button AAC palette: `Yes`, `No`, `Wait`, `Need Help`.
   - Accessible by swiping down Notification Center from any active app without leaving the current app.

### 3.2 Data Contracts & AppIntent Dispatch

```swift
import ActivityKit
import AppIntents
import SwiftUI

public struct FloatingCommunicatorAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var lastSpokenText: String?
        public var timestamp: Date
    }
}

public struct SpeakQuickPhraseIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Speak Quick Phrase"
    public static var isDiscoverable: Bool = false

    @Parameter(title: "Phrase Code")
    public var phraseCode: String

    public init() {}
    public init(phraseCode: String) {
        self.phraseCode = phraseCode
    }

    public func perform() async throws -> some IntentResult {
        // 1. Resolve offline phrase text
        let text: String
        switch phraseCode {
        case "yes": text = "Yes"
        case "no": text = "No"
        case "wait": text = "Please wait"
        default: text = "I need help"
        }

        // 2. Local on-device speech synthesis
        await SpeechService.shared.speakDirect(text: text)

        // 3. Record privacy-preserving telemetry
        UsabilityTracker.shared.startIntent("floating_communicator_used")
        UsabilityTracker.shared.endIntent(
            "floating_communicator_used",
            outcome: phraseCode,
            contextTag: "live_activity"
        )

        return .result()
    }
}
```

---

## 4. Privacy & Zero-PII Offline Guarantees

1. **Zero Remote Live Activity Push**: Sotto will **not** request or configure remote APNs push tokens for Live Activities. All lifecycle operations occur strictly via local `Activity.request(attributes:content:)`.
2. **Zero Text Retention in App Group Storage**: The shared `ContentState` contains only static identifiers (`yes`, `no`, `wait`, `help`). Custom phrase text is never serialized into shared extension containers.
3. **Local Audio Pipeline**: Speech execution utilizes native `AVSpeechSynthesizer` with pre-installed neural / enhanced offline voice packages.

---

## 5. Telemetry Specification

Consistent with the flight rules in `AGENTS.md`, activation and usage of the floating communicator must be instrumented through `UsabilityTracker`:

- **Activation Intent**: `floating_communicator_toggle`
  - Outcome: `started` | `stopped`
- **Speech Intent**: `floating_communicator_used`
  - Outcome: `yes` | `no` | `wait` | `help`
  - Friction Tag: `none`
  - Context Tag: `live_activity` | `control_widget` | `action_button`
- **Gating**: Strictly suppressed unless `voiceSettings.shareUsabilityMetrics == true`.

---

## 6. Implementation Roadmap

- **Phase 1 (Milestone v1.8.0)**:
  - Add `FloatingCommunicatorWidgetExtension` target in `project.yml`.
  - Implement `FloatingCommunicatorAttributes` and Dynamic Island layout.
  - Implement `SpeakQuickPhraseIntent` with background audio session.
- **Phase 2 (Milestone v1.8.1)**:
  - Add iOS 18 `@available(iOS 18.0, *)` `ControlWidget` for the Control Center grid.
  - Expose `AppShortcutsProvider` for Action Button binding on iPhone 15 Pro / 16.
