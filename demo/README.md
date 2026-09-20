# Sotto Demo Videos (iOS)

### TL;DR
This directory contains high-definition, synchronized demo videos showcasing Sotto's core features (Quick Speak, Emergency Hero Card, Contextual Categories, Fullscreen Presentation Mode, Card Reordering, and Voice Settings with Attention Chime) for both Indonesian and English on iOS.

---

## Videos

- **Indonesian Demo**: [`sotto_demo_id.mp4`](sotto_demo_id.mp4) (~64s, 1206×2622 @ 30fps H.264, 192 kbps AAC audio)
  - Spoken TTS Voice: `Damayanti` (id-ID) & `Samantha` (en-US)
  - Phrases: *"Tolong beri saya waktu."*, *"Saya tidak bisa bicara sekarang. Tolong baca layar saya."*, *"Halo, ini adalah suara bicara saya."*, *"Terima kasih banyak"*, *"Thank you very much"*
- **English Demo**: [`sotto_demo_en.mp4`](sotto_demo_en.mp4) (~64s, 1206×2622 @ 30fps H.264, 192 kbps AAC audio)
  - Spoken TTS Voice: `Samantha` (en-US) & `Damayanti` (id-ID)
  - Phrases: *"I need a moment, please."*, *"I cannot speak right now. Please read my screen."*, *"Hello, this is my speaking voice."*, *"Thank you very much"*, *"Terima kasih banyak"*

---

## How to Reproduce / Re-record

### Prerequisites

1. **iOS Simulator**:
   - Modern iPhone simulator (e.g. iPhone 18 Pro / iPhone 16 Pro / iPhone 15 Pro).
   - Booted via `xcrun simctl boot <device-uuid>` or Xcode.
2. **FFmpeg**:
   ```bash
   brew install ffmpeg
   ```
3. **Xcode Command Line Tools (`xcrun simctl`)**:
   Ensure `xcrun` and `xcodebuild` are available in `$PATH`.
4. **macOS TTS Voices** (used by Python audio generators):
   - English: `Samantha` (macOS default)
   - Indonesian: `Damayanti` (install via *System Settings > Accessibility > Spoken Content > Voices > Indonesian*)

---

### Recording Commands

#### 1. Record Indonesian Demo
```bash
./scripts/record_demo_id.sh
```

#### 2. Record English Demo
```bash
./scripts/record_demo_en.sh
```

---

## How the Pipeline Works

1. **Clean Environment Configuration**:
   - Pre-populates the app with standard English or Indonesian phrase sets and default settings.
   - Embeds a smooth touch cursor overlay (`DemoTouchOverlay`) to clearly visualize taps, long-presses, and card drag interactions in the video recording.
2. **Synchronized UI Automation**:
   - [`scripts/run_demo_flow_id.sh`](../scripts/run_demo_flow_id.sh) / [`scripts/run_demo_flow_en.sh`](../scripts/run_demo_flow_en.sh) drives the UI using launch arguments (`--demo-flow-id` / `--demo-flow-en`).
   - Each speech or chime interaction logs a high-precision relative timestamp (e.g. `speak_waktu_1:4.660`) to `/tmp/sotto_demo_events.txt`.
3. **Audio Synthesis**:
   - [`scripts/generate_audio_id.py`](../scripts/generate_audio_id.py) / [`scripts/generate_audio.py`](../scripts/generate_audio.py) replicates the exact two-tone Attention Chime synthesis from [`ChimePlayer.swift`](../Sotto/Services/ChimePlayer.swift) (D5 587.33 Hz + A5 880.00 Hz) and generates spoken TTS clips.
4. **Muxing**:
   - [`scripts/mux_audio_id.py`](../scripts/mux_audio_id.py) / [`scripts/mux_audio.py`](../scripts/mux_audio.py) places the audio clips along the timeline according to the logged event timestamps and muxes the video and audio tracks via FFmpeg into the final MP4.
