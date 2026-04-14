# Internet Speed Menu Bar

A macOS menu bar app that periodically runs internet speed tests and displays your download/upload speeds.

![menu bar example](https://img.shields.io/badge/menu%20bar-%E2%86%93120%20%E2%86%9125%20Mbps-blue)

## Features

- Displays download and upload speeds in the menu bar
- Configurable test interval (5, 15, 30, or 60 minutes)
- Run a speed test manually at any time
- Starts automatically on login

## Requirements

- macOS
- Python 3.9+
- [Homebrew](https://brew.sh) (the install script uses it to install the Speedtest CLI)

## Install

```bash
git clone https://github.com/samjkwong/internet-speed.git
cd internet-speed
./install.sh
```

This will:
1. Install the [Ookla Speedtest CLI](https://www.speedtest.net/apps/cli) via Homebrew (if not already installed)
2. Create a Python virtual environment
3. Install dependencies
4. Register a LaunchAgent so the app starts on login
5. Start the app immediately

The speed test icon will appear in your menu bar.

## Uninstall

```bash
./uninstall.sh
```

## Usage

- **Menu bar** shows `↓120 ↑25 Mbps` (download/upload)
- **Click** to open the dropdown menu
- **Run Test Now** triggers an immediate speed test
- **Interval** options let you change how often tests run (default: 15 min)

## Development

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt -r requirements-dev.txt
```

Run tests:

```bash
pytest speed_menu_test.py -v
```

Run the app directly (foreground, for testing):

```bash
./run.sh
```

## How It Works

The app uses [rumps](https://github.com/jaredks/rumps) for the macOS menu bar UI and [Ookla's official Speedtest CLI](https://www.speedtest.net/apps/cli) to measure internet speed. Speed tests run in a background thread so the UI stays responsive. A macOS LaunchAgent keeps the app running across logins.
