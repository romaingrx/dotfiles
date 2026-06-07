#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/env.sh"
sketchybar_resolve_paths "$SCRIPT_DIR"

source "$CONFIG_DIR/colors.sh" || exit 1
source "$CONFIG_DIR/icons.sh"
source "$HELPER_DIR/aerospace.sh"
source "$HELPER_DIR/app_icons.sh"
source "$HELPER_DIR/display_map.sh"
source "$HELPER_DIR/text.sh"

MAX_WORKSPACE_APPS="${MAX_WORKSPACE_APPS:-4}"
MAX_WORKSPACE_POPUP_ROWS="${MAX_WORKSPACE_POPUP_ROWS:-6}"

workspace_app_icons() {
	local workspace="$1"
	local max="${2:-$MAX_WORKSPACE_APPS}"
	local app bundle icon
	local count=0
	local total=0
	local icons=""

	while IFS="|" read -r app bundle; do
		[ -n "$app" ] || continue
		total=$((total + 1))

		if [ "$count" -lt "$max" ]; then
			icon="$(app_ligature "$bundle" "$app")"
			icons="${icons}${icons:+ }$icon"
			count=$((count + 1))
		fi
	done <<EOF
$(aerospace_workspace_apps "$workspace")
EOF

	if [ "$total" -gt "$max" ]; then
		icons="$icons +$((total - max))"
	fi

	printf "%s" "$icons"
}

hide_popup_rows() {
	local workspace="$1"
	local i=1

	while [ "$i" -le "$MAX_WORKSPACE_POPUP_ROWS" ]; do
		sketchybar --set "space.$workspace.window.$i" drawing=off
		i=$((i + 1))
	done
}

update_popup() {
	local workspace="$1"
	local window_count="$2"
	local layout="$3"
	local summary="No windows"
	local windows window_id app bundle title image_source icon label row click_script
	local index=1

	hide_popup_rows "$workspace"

	if [ "$window_count" -gt 0 ]; then
		summary="$window_count windows - $(text_human_layout "$layout")"
	fi

	sketchybar --set "space.$workspace.summary" \
		icon="$LAYOUT_ICN" \
		label="$summary"

	windows="$(aerospace_workspace_windows "$workspace")"
	while IFS="|" read -r window_id app bundle title; do
		[ -n "$window_id" ] || continue
		[ "$index" -le "$MAX_WORKSPACE_POPUP_ROWS" ] || break

		if [ -n "$title" ]; then
			label="$(text_truncate "$app - $title" 54)"
		else
			label="$(text_truncate "$app" 54)"
		fi

		row="space.$workspace.window.$index"
		click_script="aerospace focus --window-id $window_id; sketchybar --set space.$workspace popup.drawing=off"
		image_source="$(app_image_source "$bundle" "$app")"

		if [ -n "$image_source" ]; then
			sketchybar --set "$row" \
				drawing=on \
				icon=" " \
				icon.drawing=on \
				icon.background.drawing=on \
				icon.background.image="$image_source" \
				label="$label" \
				click_script="$click_script"
		else
			icon="$(app_ligature "$bundle" "$app")"
			sketchybar --set "$row" \
				drawing=on \
				icon.drawing=on \
				icon="$icon" \
				icon.background.drawing=off \
				label="$label" \
				click_script="$click_script"
		fi

		index=$((index + 1))
	done <<EOF
$windows
EOF
}

workspace="${NAME#space.}"
state="$(aerospace_workspace_state "$workspace")"
IFS="|" read -r _workspace is_focused is_visible display layout <<EOF
$state
EOF
display="$(display_map_sketchybar_display_for_workspace "$workspace" "$state" || true)"

event_focused_workspace="${FOCUSED_WORKSPACE:-}"
focused_workspace="${event_focused_workspace:-$(aerospace_focused_workspace)}"
window_count="$(aerospace_workspace_window_count "$workspace")"
apps_label="$(workspace_app_icons "$workspace")"

icon_color="$WHITE"
label_color="$GREY"
background_color="$TRANSPARENT"
background_drawing=off
label_drawing=on

if [ -z "$apps_label" ]; then
	label_drawing=off
fi

if { [ -n "$event_focused_workspace" ] && [ "$workspace" = "$event_focused_workspace" ]; } ||
	{ [ -z "$event_focused_workspace" ] && { [ "$workspace" = "$focused_workspace" ] || [ "$is_focused" = "true" ]; }; }; then
	icon_color="$WHITE"
	label_color="$WHITE"
	background_color="$SPACE_FOCUSED_BG"
	background_drawing=on
elif [ "$is_visible" = "true" ]; then
	icon_color="$BLUE"
	label_color="$WHITE"
	background_color="$SPACE_VISIBLE_BG"
	background_drawing=on
elif [ "$window_count" -eq 0 ]; then
	icon_color="$GREY"
	label_color="$GREY"
fi

display_properties=()
if [ -n "$display" ]; then
	display_properties=(display="$display")
fi

sketchybar --set "$NAME" \
	drawing=on \
	"${display_properties[@]}" \
	icon="$workspace" \
	icon.color="$icon_color" \
	label="$apps_label" \
	label.color="$label_color" \
	label.drawing="$label_drawing" \
	background.color="$background_color" \
	background.drawing="$background_drawing"

update_popup "$workspace" "$window_count" "$layout"
