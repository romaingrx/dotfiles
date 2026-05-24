#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${CONFIG_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"

source "$CONFIG_DIR/icons.sh"

if [[ $(defaults read -g AppleInterfaceStyle 2>/dev/null) == "Dark" ]]; then
	sketchybar -m --set appearance icon="$SUN_ICN"
else
	sketchybar -m --set appearance icon="$MOON_ICN"
fi
