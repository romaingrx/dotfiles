#!/usr/bin/env bash

_DISPLAY_MAP_HELPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_DISPLAY_MAP_HELPER_DIR/aerospace.sh"
unset _DISPLAY_MAP_HELPER_DIR

display_map_cache_file() {
	printf "%s" "${SKETCHYBAR_DISPLAY_MAP_CACHE:-${TMPDIR:-/tmp}/sketchybar-display-map-${UID:-$(/usr/bin/id -u)}.cache}"
}

display_map_appkit_direct_display_ids() {
	/usr/bin/osascript -l JavaScript <<'EOF'
ObjC.import("AppKit");

const screens = $.NSScreen.screens;
const lines = [];
for (let i = 0; i < screens.count; i++) {
	const screen = screens.objectAtIndex(i);
	const displayID = ObjC.unwrap(screen.deviceDescription.objectForKey("NSScreenNumber"));
	lines.push(`${i + 1}|${displayID}`);
}
lines.join("\n");
EOF
}

display_map_sketchybar_display_for_direct_display_id() {
	local direct_display_id="$1"
	local jq_bin displays

	case "$direct_display_id" in
	"" | *[!0-9]*) return 1 ;;
	esac

	jq_bin="$(command -v jq 2>/dev/null || true)"
	[ -n "$jq_bin" ] || return 1

	displays="$(sketchybar_query displays || true)"
	[ -n "$displays" ] || return 1

	printf "%s" "$displays" |
		"$jq_bin" -r --arg direct_display_id "$direct_display_id" '
			.[] |
			select(((.DirectDisplayID // 0) | tostring) == $direct_display_id) |
			.["arrangement-id"]
		' |
		head -n 1
}

display_map_build() {
	local appkit_screen_id direct_display_id sketchybar_display

	display_map_appkit_direct_display_ids |
		while IFS="|" read -r appkit_screen_id direct_display_id; do
			[ -n "$appkit_screen_id" ] || continue
			sketchybar_display="$(display_map_sketchybar_display_for_direct_display_id "$direct_display_id")"
			[ -n "$sketchybar_display" ] || continue

			printf "%s|%s|%s\n" "$appkit_screen_id" "$direct_display_id" "$sketchybar_display"
		done
}

display_map_refresh() {
	local cache_file tmp_file

	cache_file="$(display_map_cache_file)"
	tmp_file="${cache_file}.$$"

	display_map_build >"$tmp_file" || {
		rm -f "$tmp_file"
		return 1
	}

	if [ ! -s "$tmp_file" ]; then
		rm -f "$tmp_file"
		return 1
	fi

	mv "$tmp_file" "$cache_file"
}

display_map_invalidate() {
	rm -f "$(display_map_cache_file)"
}

display_map_entry_count() {
	local cache_file

	cache_file="$(display_map_cache_file)"
	[ -r "$cache_file" ] || return 1

	awk -F "|" 'NF >= 3 { count++ } END { print count + 0 }' "$cache_file"
}

display_map_lookup_appkit_screen_id() {
	local appkit_screen_id="$1"
	local cache_file display

	case "$appkit_screen_id" in
	"" | *[!0-9]*) return 1 ;;
	esac

	cache_file="$(display_map_cache_file)"
	if [ ! -r "$cache_file" ]; then
		display_map_refresh || return 1
	fi

	display="$(awk -F "|" -v appkit_screen_id="$appkit_screen_id" '$1 == appkit_screen_id { print $3; exit }' "$cache_file")"
	if [ -z "$display" ]; then
		display_map_refresh || return 1
		display="$(awk -F "|" -v appkit_screen_id="$appkit_screen_id" '$1 == appkit_screen_id { print $3; exit }' "$cache_file")"
	fi

	[ -n "$display" ] || return 1
	printf "%s" "$display"
}

display_map_sketchybar_display_for_appkit_screen_id() {
	local appkit_screen_id="$1"
	local display

	display="$(display_map_lookup_appkit_screen_id "$appkit_screen_id")" || return 1
	sketchybar_display_exists "$display" || return 1

	printf "%s" "$display"
}

display_map_appkit_screen_id_from_workspace_state() {
	local state="$1"
	local workspace is_focused is_visible appkit_screen_id layout

	IFS="|" read -r workspace is_focused is_visible appkit_screen_id layout <<EOF
$state
EOF

	[ -n "$appkit_screen_id" ] || return 1
	printf "%s" "$appkit_screen_id"
}

display_map_sketchybar_display_for_workspace() {
	local workspace="$1"
	local state="${2:-}"
	local appkit_screen_id

	[ -n "$workspace" ] || return 1

	if [ -z "$state" ]; then
		state="$(aerospace_workspace_state "$workspace")"
	fi

	appkit_screen_id="$(display_map_appkit_screen_id_from_workspace_state "$state")" || return 1
	display_map_sketchybar_display_for_appkit_screen_id "$appkit_screen_id"
}
