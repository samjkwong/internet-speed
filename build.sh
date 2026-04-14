#!/bin/bash
# Build Internet Speed as a macOS .app bundle.
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Internet Speed"
APP_BUNDLE="$DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "==> Building release binary..."
cd "$DIR"
swift build -c release --quiet

echo "==> Assembling .app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS" "$RESOURCES"

cp "$DIR/.build/release/InternetSpeed" "$MACOS/InternetSpeed"
cp "$DIR/Sources/InternetSpeed/Info.plist" "$CONTENTS/Info.plist"
cp "$DIR/Sources/InternetSpeed/AppIcon.icns" "$RESOURCES/AppIcon.icns"

echo "==> Done: $APP_BUNDLE"
