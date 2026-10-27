#!/usr/bin/env bash

sketchybar_resolve_paths() {
	local script_dir="$1"
	local config_root

	config_root="$(cd "$script_dir/.." && pwd)"

	if [ -z "${CONFIG_DIR:-}" ] || [ ! -r "$CONFIG_DIR/colors.sh" ]; then
		CONFIG_DIR="$config_root"
	fi
	if [ -z "${PLUGIN_DIR:-}" ] || [ ! -d "$PLUGIN_DIR" ]; then
		PLUGIN_DIR="$CONFIG_DIR/plugins"
	fi
	if [ -z "${HELPER_DIR:-}" ] || [ ! -d "$HELPER_DIR" ]; then
		HELPER_DIR="$CONFIG_DIR/helpers"
	fi

	# Fonts fall back to these when colors.sh (lib/theme) has not set them.
	# APP_FONT is the SketchyBar glyph font.
	: "${FONT:=FiraCode Nerd Font}"
	: "${NERD_FONT:=FiraCode Nerd Font}"
	: "${APP_FONT:=sketchybar-app-font}"
	: "${STATUS_RADIUS:=6}"
	: "${STATUS_HEIGHT:=22}"
	: "${STATUS_GAP:=7}" # on each side of a right-side item

	export CONFIG_DIR PLUGIN_DIR HELPER_DIR FONT NERD_FONT APP_FONT
	export STATUS_BG STATUS_RADIUS STATUS_HEIGHT STATUS_GAP
}
