#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="${CONFIG_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"

osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to not dark mode'

"$CONFIG_DIR/plugins/darkmode.sh"
