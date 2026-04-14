#!/bin/bash
# Uninstall the Internet Speed menu bar app.
set -e

BINARY="$HOME/.local/bin/InternetSpeed"
PLIST="$HOME/Library/LaunchAgents/com.internetspeed.menubar.plist"

echo "==> Stopping the app..."
launchctl unload "$PLIST" 2>/dev/null || true

echo "==> Removing LaunchAgent..."
rm -f "$PLIST"

echo "==> Removing binary..."
rm -f "$BINARY"

echo ""
echo "Done! The app has been stopped and removed."
echo "To also remove speed test history: rm -rf ~/Library/Application\\ Support/InternetSpeed"
