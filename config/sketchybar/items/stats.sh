#!/usr/bin/env bash

# CPU, memory and network as braille graphs, fed by `sketchybar-stats`
# (providers/stats.sh). Hovering shows the last two minutes.
#
# typographical_width: sketchybar sizes text by its ink by default, so the
# blank braille cells of a graph would count for nothing and the label would
# be clipped.

# stats_item NAME ICON ROWS: a bar item with ROWS popup rows, NAME.0 on.
stats_item() {
	local name="stats.$1" row

	sketchybar --add item "$name" right \
		--set "$name" \
		icon="$2" \
		icon.color="$THEME_MUTED" \
		icon.padding_left=6 \
		icon.padding_right=6 \
		label.font="$FONT:Medium:12.0" \
		label.font.typographical_width=on \
		label.padding_left=0 \
		label.padding_right=7 \
		background.drawing=on \
		background.color="$STATUS_BG" \
		background.corner_radius="$STATUS_RADIUS" \
		background.height="$STATUS_HEIGHT" \
		background.padding_left=3 \
		background.padding_right=3 \
		script="$PLUGIN_DIR/stats_hover.sh" \
		popup.background.color="$POPUP_BG" \
		popup.background.border_color="$THEME_SURFACE" \
		popup.background.border_width=1 \
		popup.blur_radius=50 \
		popup.background.corner_radius=6 \
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

if command -v sketchybar-stats >/dev/null; then
	pkill -f bin/sketchybar-stats
	sketchybar-stats &
fi
