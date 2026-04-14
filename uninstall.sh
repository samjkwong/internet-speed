#!/bin/bash
# Uninstall the internet speed menu bar app.
set -e

PLIST="$HOME/Library/LaunchAgents/com.speedtest.menubar.plist"

echo "==> Stopping the app..."
launchctl unload "$PLIST" 2>/dev/null || true

echo "==> Removing LaunchAgent..."
rm -f "$PLIST"

echo ""
echo "Done! The app has been stopped and removed from login items."
echo "You can delete this directory to fully remove it."
