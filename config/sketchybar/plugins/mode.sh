#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/env.sh"
sketchybar_resolve_paths "$SCRIPT_DIR"

source "$CONFIG_DIR/colors.sh" || exit 1
source "$CONFIG_DIR/icons.sh"
source "$HELPER_DIR/aerospace.sh"

mode="$(aerospace_current_mode)"
mode="${mode:-main}"

if [ "$mode" = "main" ]; then
	sketchybar --set mode.indicator \
		drawing=off \
		label=main \
		popup.drawing=off
	exit 0
fi

sketchybar --set mode.indicator \
	drawing=on \
	icon="$LAYOUT_ICN" \
	icon.color="$MAGENTA" \
	label="$mode" \
	label.color="$MAGENTA"
