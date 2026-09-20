#!/usr/bin/env bash
set -e

SIMULATOR_DEVICE="${SIMULATOR_DEVICE:-booted}"
EVENTS_FILE="/tmp/sotto_demo_events.txt"
rm -f "$EVENTS_FILE"

echo "Terminating previous instance of Sotto..."
xcrun simctl terminate "$SIMULATOR_DEVICE" com.amh.sotto 2>/dev/null || true
sleep 1

echo "Launching Sotto with --demo-flow-id..."
xcrun simctl launch "$SIMULATOR_DEVICE" com.amh.sotto --demo-flow-id

echo "Waiting for Indonesian demo flow to complete..."
TIMEOUT=60
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    if [ -f "$EVENTS_FILE" ] && grep -q "end:" "$EVENTS_FILE"; then
        echo "Demo flow completed successfully."
        break
    fi
    sleep 1
    ELAPSED=$((ELAPSED + 1))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    echo "Warning: Demo flow timed out."
fi
