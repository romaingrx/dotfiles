#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/env.sh"
sketchybar_resolve_paths "$SCRIPT_DIR"

source "$CONFIG_DIR/icons.sh"

if [[ $(defaults read -g AppleInterfaceStyle 2>/dev/null) == "Dark" ]]; then
	sketchybar -m --set appearance icon="$SUN_ICN"
else
	sketchybar -m --set appearance icon="$MOON_ICN"
fi
