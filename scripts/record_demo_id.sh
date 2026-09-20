#!/usr/bin/env bash
set -e

SIMULATOR_DEVICE="${SIMULATOR_DEVICE:-booted}"
APP_PATH="${APP_PATH:-$(find ~/Library/Developer/Xcode/DerivedData/Sotto-*/Build/Products/Debug-iphonesimulator/Sotto.app -maxdepth 0 2>/dev/null | head -n 1)}"

echo "Ensuring Sotto is installed on simulator..."
if [ -n "$APP_PATH" ] && [ -d "$APP_PATH" ]; then
    xcrun simctl install "$SIMULATOR_DEVICE" "$APP_PATH"
fi

echo "Generating Indonesian audio clips..."
python3 scripts/generate_audio_id.py

mkdir -p demo
RAW_VIDEO="demo/sotto_demo_id_video.mp4"
rm -f "$RAW_VIDEO"
rm -f /tmp/sotto_start_demo.txt /tmp/sotto_demo_events.txt /tmp/sotto_rec_id.log

# 1. Terminate previous instance
xcrun simctl terminate "$SIMULATOR_DEVICE" com.amh.sotto 2>/dev/null || true
sleep 1

# 2. Launch Sotto with --demo-flow-id (it initializes and waits for trigger file)
echo "Launching Sotto with --demo-flow-id..."
xcrun simctl launch "$SIMULATOR_DEVICE" com.amh.sotto --demo-flow-id
sleep 3.5 # Wait for app to render and register element coordinates

# 3. Start screen recording
echo "Starting screen recording on simulator..."
RECORD_LOG="/tmp/sotto_rec_id.log"
xcrun simctl io "$SIMULATOR_DEVICE" recordVideo --codec=h264 --force "$RAW_VIDEO" 2>"$RECORD_LOG" &
REC_PID=$!

# 4. Wait for 'Recording started' to ensure exact t=0 synchronization
echo "Waiting for video capture to start..."
TIMEOUT=50
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    if grep -q "Recording started" "$RECORD_LOG" 2>/dev/null; then
        break
    fi
    sleep 0.1
    ELAPSED=$((ELAPSED + 1))
done

# Write exact start epoch
RECORD_START_EPOCH=$(python3 -c 'import time; print(f"{time.time():.4f}")')
echo "$RECORD_START_EPOCH" > /tmp/sotto_start_demo.txt
echo "Video recording started at epoch $RECORD_START_EPOCH. Demo flow triggered."

# 5. Wait for demo flow to complete
TIMEOUT=65
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    if [ -f "/tmp/sotto_demo_events.txt" ] && grep -q "end:" "/tmp/sotto_demo_events.txt"; then
        echo "Demo flow completed successfully."
        break
    fi
    sleep 1
    ELAPSED=$((ELAPSED + 1))
done

echo "Finishing recording..."
sleep 1.5
kill -2 "$REC_PID" 2>/dev/null || true
wait "$REC_PID" 2>/dev/null || true
sleep 2

# Copy events file
if [ -f "/tmp/sotto_demo_events.txt" ]; then
    cp "/tmp/sotto_demo_events.txt" demo/events_id.txt
fi

echo "Muxing video with synchronized Indonesian audio..."
python3 scripts/mux_audio_id.py

# Optional: Copy to artifact directory if set
if [ -n "$ARTIFACT_DIR" ] && [ -d "$ARTIFACT_DIR" ]; then
    cp demo/sotto_demo_id.mp4 "$ARTIFACT_DIR/sotto_demo_id.mp4"
fi

# Clean up raw video and intermediate files
rm -f "$RAW_VIDEO" demo/sotto_soundtrack_id.wav demo/events_id.txt
rm -rf demo/audio_scratch_id /tmp/sotto_start_demo.txt /tmp/sotto_demo_events.txt /tmp/sotto_rec_id.log

echo "Indonesian demo video with synchronized sound completed: demo/sotto_demo_id.mp4"
ls -lh demo/sotto_demo_id.mp4
