#!/usr/bin/env bash
set -euo pipefail

# Sotto Asset Build & Verification Wrapper
# Resolves Python environment and invokes build_assets.py

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

python3 "$SCRIPT_DIR/build_assets.py" "$@"
