#!/usr/bin/env bash

app_icon_map_path() {
	if [ -n "${SKETCHYBAR_APP_ICON_MAP:-}" ] && [ -r "$SKETCHYBAR_APP_ICON_MAP" ]; then
		printf "%s" "$SKETCHYBAR_APP_ICON_MAP"
		return 0
	fi

	command -v icon_map.sh 2>/dev/null
}

app_load_icon_map() {
	if command -v __icon_map >/dev/null 2>&1; then
		return 0
	fi

	local icon_map
	icon_map="$(app_icon_map_path || true)"
	[ -n "$icon_map" ] && [ -r "$icon_map" ] || return 1

	source "$icon_map"
	command -v __icon_map >/dev/null 2>&1
}

app_ligature() {
	local app="${2:-}"
	local icon_result=""

	if app_load_icon_map; then
		__icon_map "$app"
	fi

	printf "%s" "${icon_result:-:default:}"
}

app_image_source() {
	local bundle="${1:-}"
	local app="${2:-}"

	if [ -n "$bundle" ]; then
		printf "app.%s" "$bundle"
	elif [ -n "$app" ]; then
		printf "app.%s" "$app"
	fi
}

app_icon() {
	app_ligature "$@"
}
