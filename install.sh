#!/bin/bash
# Install the Internet Speed menu bar app.
# Builds from source, installs the binary, and registers a LaunchAgent.
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$HOME/.local/bin"
BINARY="$INSTALL_DIR/InternetSpeed"
PLIST_NAME="com.internetspeed.menubar"
PLIST="$HOME/Library/LaunchAgents/$PLIST_NAME.plist"

echo "==> Checking for Swift..."
if ! command -v swift &>/dev/null; then
    echo "Error: Swift not found. Install Xcode Command Line Tools with: xcode-select --install"
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

echo "==> Building InternetSpeed..."
cd "$DIR"
swift build -c release --quiet

echo "==> Installing binary..."
mkdir -p "$INSTALL_DIR"
cp "$DIR/.build/release/InternetSpeed" "$BINARY"

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
        <string>$BINARY</string>
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
echo "Done! Internet Speed is now running in your menu bar."
echo "It will start automatically on login."
echo ""
echo "To uninstall, run: ./uninstall.sh"
