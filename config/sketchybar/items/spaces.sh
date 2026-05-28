#!/usr/bin/env bash

source "$HELPER_DIR/aerospace.sh"

MAX_WORKSPACE_POPUP_ROWS="${MAX_WORKSPACE_POPUP_ROWS:-6}"

sketchybar --add event aerospace_workspace_change
sketchybar --add event aerospace_monitor_change

aerospace_workspaces | while IFS= read -r sid; do
	[ -n "$sid" ] || continue

	item="space.$sid"

	sketchybar --add item "$item" left \
		--set "$item" \
		icon="$sid" \
		icon.padding_left=7 \
		icon.padding_right=5 \
		icon.font="$FONT:Medium:15.0" \
		label="" \
		label.font="$APP_FONT:Regular:13.0" \
		label.padding_left=0 \
		label.padding_right=7 \
		label.drawing=off \
		display=1 \
		background.padding_left=3 \
		background.padding_right=3 \
		background.color=0x44ffffff \
		background.corner_radius=5 \
		background.height=22 \
		background.drawing=off \
		popup.background.color=0x70000000 \
		popup.blur_radius=50 \
		popup.background.corner_radius=5 \
		popup.align=left \
		popup.height=26 \
		click_script="$PLUGIN_DIR/space_click.sh $sid"

	sketchybar --add item "$item.summary" "popup.$item" \
		--set "$item.summary" \
		icon="$WINDOW_ICN" \
		label="No windows" \
		icon.color="$GREY" \
		label.color="$GREY" \
		background.padding_left=6 \
		background.padding_right=8

	i=1
	while [ "$i" -le "$MAX_WORKSPACE_POPUP_ROWS" ]; do
		row="$item.window.$i"
		sketchybar --add item "$row" "popup.$item" \
			--set "$row" \
			drawing=off \
			icon.color="$WHITE" \
			icon.font="$APP_FONT:Regular:15.0" \
			icon.background.drawing=off \
			icon.background.height=17 \
			icon.background.corner_radius=4 \
			icon.background.image.scale=0.7 \
			icon.padding_left=2 \
			icon.padding_right=8 \
			icon.width=17 \
			label.color="$WHITE" \
			label.font="$FONT:Medium:13.0" \
			background.padding_left=6 \
			background.padding_right=8
		i=$((i + 1))
	done
done

# One hidden controller drives every workspace indicator: on each event it runs
# spaces_update.sh, which either fast-paints two items or kicks a full reconcile
# (see plugins/spaces_update.sh). updates=on so it still fires while hidden.
sketchybar --add item spaces_controller left \
	--set spaces_controller drawing=off updates=on \
	script="$PLUGIN_DIR/spaces_update.sh" \
	--subscribe spaces_controller aerospace_workspace_change aerospace_monitor_change

# Paint initial state now instead of waiting for the first workspace switch.
"$PLUGIN_DIR/spaces_update.sh" >/dev/null 2>&1 || true
