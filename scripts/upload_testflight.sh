#!/usr/bin/env bash
# scripts/upload_testflight.sh
#
# Automated local CLI archive and TestFlight upload for Sotto iOS.
# Uses local Xcode signed-in account (-allowProvisioningUpdates) by default,
# or App Store Connect API Key if ASC_KEY_ID, ASC_ISSUER_ID, and ASC_KEY_PATH are set.
#
# Usage:
#   ./scripts/upload_testflight.sh                # Archive and upload to TestFlight
#   ./scripts/upload_testflight.sh --archive-only # Build signed xcarchive without uploading

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

ARCHIVE_ONLY=false
for arg in "$@"; do
  case "$arg" in
    --archive-only|--dry-run)
      ARCHIVE_ONLY=true
      ;;
    -h|--help)
      echo "Usage: $0 [--archive-only|--dry-run]"
      echo ""
      echo "Environment variables (optional):"
      echo "  DEVELOPMENT_TEAM   Apple Developer Team ID (auto-detected from Keychain if omitted)"
      echo "  ASC_KEY_ID         App Store Connect API Key ID (optional, uses Xcode session if omitted)"
      echo "  ASC_ISSUER_ID      App Store Connect Issuer ID (optional)"
      echo "  ASC_KEY_PATH       Path to AuthKey_<KEY_ID>.p8 file (optional)"
      exit 0
      ;;
  esac
done

echo "=== 1. Running Pre-Flight Release Doc Audit ==="
python3 scripts/sync_release_docs.py --check

echo ""
echo "=== 2. Regenerating Xcode Project ==="
if ! command -v xcodegen >/dev/null 2>&1; then
  echo "Error: xcodegen is not installed. Run 'brew install xcodegen'." >&2
  exit 1
fi
xcodegen generate

# Auto-detect DEVELOPMENT_TEAM from local Keychain if not provided in environment
if [ -z "${DEVELOPMENT_TEAM:-}" ]; then
  DEVELOPMENT_TEAM="$(
    security find-certificate -c "Apple Distribution" -p 2>/dev/null \
      | openssl x509 -noout -subject 2>/dev/null \
      | sed -n 's/.*OU=\([A-Z0-9]*\).*/\1/p' \
      | head -n 1 || true
  )"
fi
if [ -z "${DEVELOPMENT_TEAM:-}" ]; then
  DEVELOPMENT_TEAM="$(
    security find-certificate -c "Apple Development" -p 2>/dev/null \
      | openssl x509 -noout -subject 2>/dev/null \
      | sed -n 's/.*OU=\([A-Z0-9]*\).*/\1/p' \
      | head -n 1 || true
  )"
fi

if [ -z "${DEVELOPMENT_TEAM:-}" ]; then
  echo "Error: Could not auto-detect DEVELOPMENT_TEAM from Keychain." >&2
  echo "Please run with: DEVELOPMENT_TEAM=<YOUR_TEAM_ID> $0" >&2
  exit 1
fi

echo "Using Development Team ID: ${DEVELOPMENT_TEAM}"

BUILD_DIR="$REPO_ROOT/build/testflight"
ARCHIVE_PATH="$BUILD_DIR/Sotto.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
EXPORT_PLIST="$BUILD_DIR/ExportOptions.plist"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Optional App Store Connect API Key flags
AUTH_FLAGS=(-allowProvisioningUpdates)
if [ -n "${ASC_KEY_ID:-}" ] && [ -n "${ASC_ISSUER_ID:-}" ] && [ -n "${ASC_KEY_PATH:-}" ]; then
  echo "Using App Store Connect API Key authentication (Key ID: ${ASC_KEY_ID})"
  AUTH_FLAGS+=(
    -authenticationKeyPath "$ASC_KEY_PATH"
    -authenticationKeyID "$ASC_KEY_ID"
    -authenticationKeyIssuerID "$ASC_ISSUER_ID"
  )
else
  echo "Using local Xcode signed-in Apple ID session (-allowProvisioningUpdates)"
fi

echo ""
echo "=== 3. Creating Release Archive ==="
xcodebuild archive \
  -project Sotto.xcodeproj \
  -scheme Sotto \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE_PATH" \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
  CODE_SIGN_STYLE=Automatic \
  "${AUTH_FLAGS[@]}"

echo "Archive created at: $ARCHIVE_PATH"

if [ "$ARCHIVE_ONLY" = true ]; then
  echo ""
  echo "=== Archive-Only Mode Complete (Skipping Upload) ==="
  exit 0
fi

echo ""
echo "=== 4. Exporting & Uploading to App Store Connect / TestFlight ==="
cat > "$EXPORT_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>destination</key>
    <string>upload</string>
    <key>teamID</key>
    <string>${DEVELOPMENT_TEAM}</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>uploadSymbols</key>
    <true/>
    <key>manageAppVersionAndBuildNumber</key>
    <true/>
</dict>
</plist>
EOF

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist "$EXPORT_PLIST" \
  -exportPath "$EXPORT_PATH" \
  "${AUTH_FLAGS[@]}"

echo ""
echo "✅ Successfully uploaded Sotto to App Store Connect / TestFlight!"
echo "Check processing status at: https://appstoreconnect.apple.com"
