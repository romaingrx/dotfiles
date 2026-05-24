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

	: "${FONT:=IBM Plex Mono}"
	: "${NERD_FONT:=JetBrainsMono Nerd Font}"
	: "${APP_FONT:=sketchybar-app-font}"
	: "${STATUS_BG:=0x22000000}"
	: "${STATUS_GRAPH_BG:=0x16000000}"
	: "${STATUS_RADIUS:=6}"
	: "${STATUS_HEIGHT:=22}"
	: "${STATUS_GRAPH_WIDTH:=42}"
	: "${STATUS_GRAPH_LABEL_WIDTH:=34}"

	export CONFIG_DIR PLUGIN_DIR HELPER_DIR FONT NERD_FONT APP_FONT
	export STATUS_BG STATUS_GRAPH_BG STATUS_RADIUS STATUS_HEIGHT
	export STATUS_GRAPH_WIDTH STATUS_GRAPH_LABEL_WIDTH
}
