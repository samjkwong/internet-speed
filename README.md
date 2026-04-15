# Internet Speed

A native macOS menu bar app that periodically runs internet speed tests and displays your download/upload speeds with a history chart.

![menu bar example](https://img.shields.io/badge/menu%20bar-%E2%86%93120%20%E2%86%9125%20Mbps-blue)

<p align="center">
  <img src="screenshot.svg" alt="Internet Speed dashboard" width="320">
</p>

## Features

- Native SwiftUI menu bar app with a popover dashboard
- Download/upload speed chart over time (Swift Charts)
- Configurable test interval (5, 15, 30, or 60 minutes)
- Run a speed test manually at any time
- Persists speed history across restarts
- Installs as a proper `.app` in /Applications
- Uses [Ookla's official Speedtest CLI](https://www.speedtest.net/apps/cli) for accurate results

## Requirements

- macOS 14+
- [Ookla Speedtest CLI](https://www.speedtest.net/apps/cli) (see install steps below)

## Install

### Quick install (recommended)

Download the latest `.app` from the [Releases page](https://github.com/samjkwong/internet-speed/releases) — no Xcode or build tools needed.

1. Download `Internet.Speed.app.zip` from [the latest release](https://github.com/samjkwong/internet-speed/releases/latest)
2. Unzip and drag **Internet Speed.app** to `/Applications`
3. Remove the macOS quarantine flag (required for unsigned apps):
   ```bash
   xattr -cr "/Applications/Internet Speed.app"
   ```
4. Install the Ookla Speedtest CLI (if you don't have it):
   ```bash
   brew tap teamookla/speedtest
   brew install teamookla/speedtest/speedtest
   ```
5. Open the app — it will appear in your menu bar

To start on login, go to **System Settings > General > Login Items** and add "Internet Speed".

### Build from source

Requires Xcode and [Homebrew](https://brew.sh).

```bash
git clone https://github.com/samjkwong/internet-speed.git
cd internet-speed
./install.sh
```

This will install the Speedtest CLI (if needed), build the `.app` from source, copy it to `/Applications`, and launch it.

## Uninstall

```bash
./uninstall.sh
```

## Usage

Click the speed indicator in your menu bar to open the dashboard:

- **Current speeds** shown at the top
- **Chart** displays download/upload history over time
- **Run Test Now** triggers an immediate speed test
- **Interval picker** lets you change how often tests run (default: 15 min)

## Development

Build the `.app` bundle:

```bash
./build.sh
open "Internet Speed.app"
```

## How It Works

The app uses SwiftUI's `MenuBarExtra` with a `.window` style for the popover UI, Swift Charts for the speed history graph, and Ookla's official Speedtest CLI to measure internet speed. Speed tests run on a background thread so the UI stays responsive. Results are persisted to `~/Library/Application Support/InternetSpeed/history.json`.
