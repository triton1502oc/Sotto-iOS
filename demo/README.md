# Sotto Demo Videos (iOS)

### TL;DR
High-definition demo videos and reproduction scripts showcasing Sotto's flagship assistive communication and crisis navigation features on iOS—including **Two-Way Caregiver Receptive Mode** (180° face-to-face screen flip and rapid triage responses), **Two-Tier Quick-Speak Bar**, **Bystander Safety Hero Card**, **Sensory Color Themes**, and the **Two-Tone Attention Chime**.

---

## Demo Videos

| Video | Format | Primary Lang | Audio / Voice | Specs | File |
|---|---|---|---|---|---|
| **App Store Preview (Master)** | 16:9 Landscape | `en-US` | Neural Baritone Christopher + Andrew + Ambient Bed + Chime | 1920×1080 @ 30fps, 60s | [`sotto_app_store_preview.mp4`](sotto_app_store_preview.mp4) |
| **Shorts / Reels / TikTok (Vertical)** | 9:16 Portrait | `en-US` | Neural Baritone Christopher + Andrew + Ambient Bed + Chime | 1080×1920 @ 30fps, 60s | [`sotto_vertical_preview.mp4`](sotto_vertical_preview.mp4) |
| **English Device Demo** | 9:19.5 Portrait | `en-US` | Samantha & Damayanti | 1206×2622 @ 30fps, ~64s | [`sotto_demo_en.mp4`](sotto_demo_en.mp4) |
| **Indonesian Device Demo** | 9:19.5 Portrait | `id-ID` | Damayanti & Samantha | 1206×2622 @ 30fps, ~64s | [`sotto_demo_id.mp4`](sotto_demo_id.mp4) |

---

## Featured Capabilities

1. **Modern Two-Tier Quick-Speak Bar**: Spontaneous text input, instant speech playback (`🔊`), and large-card fullscreen modal (`⛶`).
2. **Safety Bystander Mode & Fullscreen Card**: Category filtering and high-contrast emergency card with digit-by-digit phone number TTS.
3. **Two-Way Caregiver Receptive Mode**: Dedicated receptive HUD, caregiver question prompt bank, 180° face-to-face tabletop screen flip (`🔄 Flip`), and dignified rapid-response buttons (`✓ Yes` / `✕ No` / `❔ Not sure` / `🛑 Stop`) with instant voice confirmation.
4. **Why Finder Diagnostic Tree**: Binary yes/no inquiry tree to discover root triggers (physical pain, sensory overload, fatigue) calmly.
5. **Private Why Log & 30-Day Trends**: 100% on-device private crisis event logging with environmental trend insights.
6. **Voice Customization & Attention Chime**: Two-tone pre-speech alert chime (D5 587.33 Hz + A5 880.00 Hz) and configurable speech rate/pitch.
7. **5 Sensory Color Themes**: Charcoal, OLED Pure Black, Warm Amber, Slate Navy, and Soft Parchment for photophobia comfort.

---

## Recording & Reproduction

### Prerequisites
- **iOS Simulator**: iPhone with Dynamic Island (e.g. iPhone 17 / iPhone 16 Pro) booted via `xcrun simctl boot <uuid>`.
- **Tools**: `ffmpeg` (`brew install ffmpeg`), Xcode Command Line Tools (`xcrun`, `xcodebuild`).
- **Python Dependencies**: `pip install --user edge-tts Pillow` (neural narration at build time only, no user data).
- **macOS TTS Voices** (for simulator recording): `Samantha` (`en_US`) and `Damayanti` (`id_ID`) (*System Settings > Accessibility > Spoken Content > Voices*).

### Commands

```bash
# 1. Build Master Neural Baritone Soundtrack (60s)
python3 scripts/build_soundtrack.py      # -> demo/sotto_soundtrack.wav

# 2. Render App Store Preview Video (16:9 Landscape 1080p)
python3 scripts/render_demo_video.py     # -> demo/sotto_app_store_preview.mp4

# 3. Render Shorts / Reels / TikTok Video (9:16 Portrait 1080x1920)
python3 scripts/render_vertical_short.py # -> demo/sotto_vertical_preview.mp4

# 4. Record Interactive Simulator Demos
./scripts/record_demo_en.sh
./scripts/record_demo_id.sh
```

---

## Pipeline Overview

1. **Clean Environment Configuration**:
   - Embeds a smooth touch cursor overlay (`DemoTouchOverlay`) to clearly visualize taps, long-presses, and card drag interactions in the video recording.
2. **Synchronized UI Automation**:
   - Drives the UI using launch arguments (`--demo-flow-en` / `--demo-flow-id`).
   - Each speech or chime interaction logs a high-precision relative timestamp (e.g. `speak_waktu_1:4.660`) to `/tmp/sotto_demo_events.txt`.
3. **Motion Preview Rendering**:
   - `scripts/render_demo_video.py` and `scripts/render_vertical_short.py` generate authentic Apple iPhone device mockups with Dynamic Island framing, kinetic typography, and interactive touch pulses.
4. **Muxing**:
   - Muxes synthesized video and audio tracks via Apple VideoToolbox hardware H.264 / AAC encoder into the final broadcast MP4s.
