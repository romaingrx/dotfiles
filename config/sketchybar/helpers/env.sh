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

	export CONFIG_DIR PLUGIN_DIR HELPER_DIR
}
