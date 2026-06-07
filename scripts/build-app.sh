#!/usr/bin/env bash
#
# Builds a runnable NotchHub.app from the SwiftPM executable.
#
#   ./scripts/build-app.sh [debug|release]   (default: release)
#
# Produces build/NotchHub.app (ad-hoc signed). For a notarized Developer-ID
# build see docs/インフラストラクチャ規約.md; this script targets local runs.
set -euo pipefail

cd "$(dirname "$0")/.."

CONFIG="${1:-release}"
APP_NAME="NotchHub"
OUT_DIR="build"
APP="$OUT_DIR/$APP_NAME.app"
CONTENTS="$APP/Contents"

echo "==> Building ($CONFIG)"
swift build -c "$CONFIG"
BIN_DIR="$(swift build -c "$CONFIG" --show-bin-path)"
BINARY="$BIN_DIR/$APP_NAME"

if [[ ! -x "$BINARY" ]]; then
    echo "error: executable not found at $BINARY" >&2
    exit 1
fi

echo "==> Assembling $APP"
rm -rf "$APP"
mkdir -p "$CONTENTS/MacOS"
cp "$BINARY" "$CONTENTS/MacOS/$APP_NAME"
cp "Resources/Info.plist" "$CONTENTS/Info.plist"
printf 'APPL????' > "$CONTENTS/PkgInfo"

echo "==> Ad-hoc signing"
# Local run: ad-hoc signature, no sandbox (sandbox entitlements need a
# provisioning profile / Developer ID — see インフラストラクチャ規約.md).
codesign --force --sign - --timestamp=none "$APP"

echo "==> Done: $APP"
echo "   Run with: open \"$APP\"   (or: \"$CONTENTS/MacOS/$APP_NAME\")"
