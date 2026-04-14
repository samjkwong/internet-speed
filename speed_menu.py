#!/usr/bin/env python3
"""macOS menu bar app that periodically runs internet speed tests."""

from dataclasses import dataclass
import json
import os
import subprocess
import threading
import time
import rumps

# LaunchAgents have a minimal PATH that may not include Homebrew.
HOMEBREW_PATHS = ("/opt/homebrew/bin", "/usr/local/bin")
SPEEDTEST_BIN = None
for _dir in (*HOMEBREW_PATHS, *os.environ.get("PATH", "").split(":")):
    _candidate = os.path.join(_dir, "speedtest")
    if os.path.isfile(_candidate) and os.access(_candidate, os.X_OK):
        SPEEDTEST_BIN = _candidate
        break


@dataclass(frozen=True)
class IntervalOption:
    minutes: int
    label: str

    @property
    def seconds(self) -> int:
        return self.minutes * 60


INTERVAL_OPTIONS = (
    IntervalOption(minutes=5, label="5 min"),
    IntervalOption(minutes=15, label="15 min"),
    IntervalOption(minutes=30, label="30 min"),
    IntervalOption(minutes=60, label="60 min"),
)

DEFAULT_INTERVAL = INTERVAL_OPTIONS[1]  # 15 min


class SpeedTestApp(rumps.App):
    def __init__(self):
        super().__init__("Speed", title="-- Mbps")
        self.current_interval = DEFAULT_INTERVAL
        self.testing = False
        self._last_test_time = 0.0

        self.dl_item = rumps.MenuItem("Download: --")
        self.ul_item = rumps.MenuItem("Upload: --")

        self.interval_items: dict[IntervalOption, rumps.MenuItem] = {}
        for option in INTERVAL_OPTIONS:
            item = rumps.MenuItem(
                f"Interval: {option.label}",
                callback=lambda _, opt=option: self._set_interval(opt),
            )
            self.interval_items[option] = item

        self.menu = [
            rumps.MenuItem("Run Test Now", callback=self.manual_test),
            None,
            self.dl_item,
            self.ul_item,
            None,
            *self.interval_items.values(),
        ]
        self._update_interval_checks()
        self._run_test_thread()

    @rumps.timer(60)
    def periodic_check(self, _):
        if time.monotonic() - self._last_test_time >= self.current_interval.seconds:
            self._run_test_thread()

    def manual_test(self, _):
        self._run_test_thread()

    def _run_test_thread(self):
        if self.testing:
            return
        self.testing = True
        self.title = "Testing..."
        threading.Thread(target=self._run_test, daemon=True).start()

    def _run_test(self):
        try:
            if not SPEEDTEST_BIN:
                raise FileNotFoundError(
                    "Ookla Speedtest CLI not found. "
                    "Install with: brew install teamookla/speedtest/speedtest"
                )

            result = subprocess.run(
                [SPEEDTEST_BIN, "--format=json", "--accept-license"],
                capture_output=True,
                text=True,
                timeout=120,
            )
            result.check_returncode()
            data = json.loads(result.stdout)

            # Ookla reports bandwidth in bytes/sec, convert to Mbps
            dl = data["download"]["bandwidth"] * 8 / 1_000_000
            ul = data["upload"]["bandwidth"] * 8 / 1_000_000

            self.title = f"↓{dl:.0f} ↑{ul:.0f} Mbps"
            self.dl_item.title = f"Download: {dl:.1f} Mbps"
            self.ul_item.title = f"Upload: {ul:.1f} Mbps"
        except Exception as e:
            self.title = "Error"
            print(f"Speed test error: {e}")
        finally:
            self._last_test_time = time.monotonic()
            self.testing = False

    def _set_interval(self, option: IntervalOption):
        self.current_interval = option
        self._update_interval_checks()

    def _update_interval_checks(self):
        for option, item in self.interval_items.items():
            item.state = 1 if option == self.current_interval else 0


if __name__ == "__main__":
    SpeedTestApp().run()
