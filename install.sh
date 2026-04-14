#!/bin/bash
# Install the internet speed menu bar app.
# Creates a virtual environment, installs dependencies, and registers a LaunchAgent.
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
PLIST_NAME="com.speedtest.menubar"
PLIST="$HOME/Library/LaunchAgents/$PLIST_NAME.plist"

echo "==> Checking for Python 3..."
if command -v python3 &>/dev/null; then
    PYTHON=python3
else
    echo "Error: python3 not found. Install with: brew install python@3.12"
    exit 1
fi

echo "==> Checking for Ookla Speedtest CLI..."
if ! command -v speedtest &>/dev/null; then
    echo "Installing Ookla Speedtest CLI..."
    brew tap teamookla/speedtest
    brew install teamookla/speedtest/speedtest
fi

echo "==> Creating virtual environment..."
"$PYTHON" -m venv "$DIR/venv"

echo "==> Installing dependencies..."
"$DIR/venv/bin/pip" install --quiet -r "$DIR/requirements.txt"

echo "==> Unloading existing LaunchAgent (if any)..."
launchctl unload "$PLIST" 2>/dev/null || true

echo "==> Installing LaunchAgent..."
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$PLIST_NAME</string>
    <key>ProgramArguments</key>
    <array>
        <string>$DIR/venv/bin/python3</string>
        <string>$DIR/speed_menu.py</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
EOF

echo "==> Starting the app..."
launchctl load "$PLIST"

echo ""
echo "Done! The speed test app is now running in your menu bar."
echo "It will start automatically on login."
echo ""
echo "To uninstall, run: ./uninstall.sh"
