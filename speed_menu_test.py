"""Unit tests for the speed test menu bar app."""

import json
from unittest.mock import MagicMock, patch
import pytest

from speed_menu import (
    IntervalOption,
    INTERVAL_OPTIONS,
    DEFAULT_INTERVAL,
    SpeedTestApp,
)


MOCK_SPEEDTEST_JSON = json.dumps({
    "download": {"bandwidth": 18750000},   # 150 Mbps (bytes/sec * 8)
    "upload": {"bandwidth": 3125000},      # 25 Mbps
    "ping": {"latency": 5.5},
    "server": {"name": "Test Server"},
})


# --- IntervalOption tests ---


class TestIntervalOption:
    def test_seconds_conversion(self):
        option = IntervalOption(minutes=5, label="5 min")
        assert option.seconds == 300

    def test_seconds_conversion_hour(self):
        option = IntervalOption(minutes=60, label="60 min")
        assert option.seconds == 3600

    def test_frozen(self):
        option = IntervalOption(minutes=5, label="5 min")
        with pytest.raises(AttributeError):
            option.minutes = 10

    def test_equality(self):
        a = IntervalOption(minutes=15, label="15 min")
        b = IntervalOption(minutes=15, label="15 min")
        assert a == b

    def test_inequality(self):
        a = IntervalOption(minutes=5, label="5 min")
        b = IntervalOption(minutes=15, label="15 min")
        assert a != b

    def test_hashable(self):
        option = IntervalOption(minutes=5, label="5 min")
        d = {option: "value"}
        assert d[option] == "value"


# --- Module-level constants tests ---


class TestConstants:
    def test_interval_options_count(self):
        assert len(INTERVAL_OPTIONS) == 4

    def test_interval_options_sorted_ascending(self):
        minutes = [opt.minutes for opt in INTERVAL_OPTIONS]
        assert minutes == sorted(minutes)

    def test_default_interval_is_15_min(self):
        assert DEFAULT_INTERVAL.minutes == 15

    def test_default_interval_in_options(self):
        assert DEFAULT_INTERVAL in INTERVAL_OPTIONS


# --- SpeedTestApp tests ---


@patch("speed_menu.SPEEDTEST_BIN", "/usr/bin/speedtest")
@patch("speed_menu.threading.Thread")
class TestSpeedTestApp:
    def test_initial_title(self, mock_thread):
        app = SpeedTestApp()
        assert app.title == "Testing..."

    def test_initial_interval(self, mock_thread):
        app = SpeedTestApp()
        assert app.current_interval == DEFAULT_INTERVAL

    def test_initial_testing_flag(self, mock_thread):
        app = SpeedTestApp()
        assert app.testing is True  # startup test is kicked off

    def test_startup_triggers_test(self, mock_thread):
        SpeedTestApp()
        mock_thread.assert_called_once()
        mock_thread.return_value.start.assert_called_once()

    def test_menu_items_present(self, mock_thread):
        app = SpeedTestApp()
        assert "Run Test Now" in app.menu
        assert "Download: --" in app.menu
        assert "Upload: --" in app.menu

    def test_interval_menu_items_present(self, mock_thread):
        app = SpeedTestApp()
        for option in INTERVAL_OPTIONS:
            assert f"Interval: {option.label}" in app.menu

    def test_default_interval_checked(self, mock_thread):
        app = SpeedTestApp()
        for option, item in app.interval_items.items():
            if option == DEFAULT_INTERVAL:
                assert item.state == 1
            else:
                assert item.state == 0

    def test_set_interval(self, mock_thread):
        app = SpeedTestApp()
        new_interval = INTERVAL_OPTIONS[0]  # 5 min
        app._set_interval(new_interval)
        assert app.current_interval == new_interval

    def test_set_interval_updates_checks(self, mock_thread):
        app = SpeedTestApp()
        new_interval = INTERVAL_OPTIONS[3]  # 60 min
        app._set_interval(new_interval)
        for option, item in app.interval_items.items():
            if option == new_interval:
                assert item.state == 1
            else:
                assert item.state == 0

    def test_run_test_thread_skips_if_already_testing(self, mock_thread):
        app = SpeedTestApp()
        mock_thread.reset_mock()
        app.testing = True
        app._run_test_thread()
        mock_thread.assert_not_called()

    def test_run_test_thread_starts_when_not_testing(self, mock_thread):
        app = SpeedTestApp()
        mock_thread.reset_mock()
        app.testing = False
        app._run_test_thread()
        mock_thread.assert_called_once()

    def test_periodic_check_triggers_when_interval_elapsed(self, mock_thread):
        app = SpeedTestApp()
        app.testing = False
        app._last_test_time = 0.0  # long ago
        mock_thread.reset_mock()
        app.periodic_check(None)
        mock_thread.assert_called_once()

    def test_periodic_check_skips_when_interval_not_elapsed(self, mock_thread):
        app = SpeedTestApp()
        app.testing = False
        mock_thread.reset_mock()
        with patch("speed_menu.time") as mock_time:
            mock_time.monotonic.return_value = 100.0
            app._last_test_time = 100.0  # just now
            app.periodic_check(None)
        mock_thread.assert_not_called()


@patch("speed_menu.threading.Thread")
class TestRunTest:
    def test_successful_test_updates_title(self, mock_thread):
        app = SpeedTestApp()

        mock_result = MagicMock()
        mock_result.stdout = MOCK_SPEEDTEST_JSON
        mock_result.check_returncode = MagicMock()

        with patch("speed_menu.SPEEDTEST_BIN", "/usr/bin/speedtest"), \
             patch("speed_menu.subprocess.run", return_value=mock_result):
            app._run_test()

        assert app.title == "↓150 ↑25 Mbps"
        assert app.dl_item.title == "Download: 150.0 Mbps"
        assert app.ul_item.title == "Upload: 25.0 Mbps"
        assert app.testing is False

    def test_failed_test_shows_error(self, mock_thread):
        app = SpeedTestApp()

        with patch("speed_menu.SPEEDTEST_BIN", "/usr/bin/speedtest"), \
             patch("speed_menu.subprocess.run", side_effect=Exception("network down")):
            app._run_test()

        assert app.title == "Error"
        assert app.testing is False

    def test_missing_binary_shows_error(self, mock_thread):
        app = SpeedTestApp()

        with patch("speed_menu.SPEEDTEST_BIN", None):
            app._run_test()

        assert app.title == "Error"
        assert app.testing is False

    def test_failed_test_updates_last_test_time(self, mock_thread):
        app = SpeedTestApp()
        app._last_test_time = 0.0

        with patch("speed_menu.SPEEDTEST_BIN", "/usr/bin/speedtest"), \
             patch("speed_menu.subprocess.run", side_effect=Exception("fail")):
            app._run_test()

        assert app._last_test_time > 0.0
