#!/usr/bin/env bash

# CPU, memory and network as bar graphs, fed by `sketchybar-stats`
# (providers/stats.sh). Hovering shows the last two minutes.
#
# typographical_width: sketchybar sizes text by its ink by default, so the
# blank cells of a graph would count for nothing and the label would
# grow as history fills in, with its end clipped.

source "$HELPER_DIR/components.sh"

# stats_item NAME ICON ROWS: a bar item with ROWS popup rows, NAME.0 on.
stats_item() {
	local name="stats.$1" row

	status_item "$name" \
		icon="$2" \
		icon.color="$THEME_MUTED" \
		label.font.typographical_width=on \
		script="$PLUGIN_DIR/stats_hover.sh" \
		popup.align=right \
		popup.height=16 \
		--subscribe "$name" mouse.entered mouse.exited mouse.exited.global

	for ((row = 0; row < $3; row++)); do
		sketchybar --add item "$name.$row" "popup.$name" \
			--set "$name.$row" \
			icon.drawing=off \
			label.font="$FONT:Regular:12.0" \
			label.font.typographical_width=on \
			label.padding_left=8 \
			label.padding_right=8
	done
}

# Added right to left: CPU ends up rightmost, as on waybar.
stats_item cpu  5
stats_item mem  5
stats_item net 󰓡 7

# A new feeder makes any earlier one exit (providers/stats.sh).
if command -v sketchybar-stats >/dev/null; then
	sketchybar-stats &
fi
