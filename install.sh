#!/bin/bash
# Install the Internet Speed menu bar app.
# Builds the .app bundle and copies it to /Applications.
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Internet Speed"

echo "==> Checking for Swift..."
if ! command -v swift &>/dev/null; then
    echo "Error: Swift not found. Install Xcode or Xcode Command Line Tools."
    exit 1
fi

echo "==> Checking for Ookla Speedtest CLI..."
if ! command -v speedtest &>/dev/null; then
    if ! command -v brew &>/dev/null; then
        echo "Error: Homebrew not found. Install from https://brew.sh"
        exit 1
    fi
    echo "    Installing Ookla Speedtest CLI..."
    brew tap teamookla/speedtest
    brew install teamookla/speedtest/speedtest
fi

echo "==> Building $APP_NAME..."
"$DIR/build.sh"

echo "==> Quitting existing instance (if any)..."
osascript -e "quit app \"$APP_NAME\"" 2>/dev/null || true
sleep 1

echo "==> Installing to /Applications..."
rm -rf "/Applications/$APP_NAME.app"
cp -R "$DIR/$APP_NAME.app" "/Applications/$APP_NAME.app"

echo "==> Launching $APP_NAME..."
open "/Applications/$APP_NAME.app"

echo ""
echo "Done! $APP_NAME is now running in your menu bar."
echo ""
echo "To start on login: System Settings > General > Login Items > add '$APP_NAME'"
echo "To uninstall, run: ./uninstall.sh"
