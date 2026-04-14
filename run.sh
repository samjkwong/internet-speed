#!/bin/bash
# Launch the speed test menu bar app
DIR="$(cd "$(dirname "$0")" && pwd)"
"$DIR/venv/bin/python3" "$DIR/speed_menu.py"
