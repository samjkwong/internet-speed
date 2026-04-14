#!/bin/bash
# Uninstall the Internet Speed menu bar app.
set -e

APP_NAME="Internet Speed"

echo "==> Quitting $APP_NAME..."
osascript -e "quit app \"$APP_NAME\"" 2>/dev/null || true
sleep 1

echo "==> Removing from /Applications..."
rm -rf "/Applications/$APP_NAME.app"

# Clean up old LaunchAgent if present
PLIST="$HOME/Library/LaunchAgents/com.internetspeed.menubar.plist"
if [ -f "$PLIST" ]; then
    echo "==> Removing old LaunchAgent..."
    launchctl unload "$PLIST" 2>/dev/null || true
    rm -f "$PLIST"
fi

echo ""
echo "Done! $APP_NAME has been removed."
echo "To also remove speed test history: rm -rf ~/Library/Application\\ Support/InternetSpeed"
