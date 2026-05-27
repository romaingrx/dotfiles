#!/usr/bin/env bash

status_graph() {
	local name="$1"
	local position="$2"
	local color="$3"
	local fill_color="$4"

	sketchybar --add graph "$name" "$position" "$STATUS_GRAPH_WIDTH" \
		--set "$name" \
		graph.color="$color" \
		graph.fill_color="$fill_color" \
		graph.line_width=0.8 \
		label=0 \
		label.drawing=on \
		label.font="$FONT:Medium:9.0" \
		label.color="$color" \
		label.width="$STATUS_GRAPH_LABEL_WIDTH" \
		label.align=right \
		label.padding_left=2 \
		label.padding_right=3 \
		icon.drawing=off \
		background.drawing=on \
		background.color="$STATUS_GRAPH_BG" \
		background.corner_radius="$STATUS_RADIUS" \
		background.height="$STATUS_GRAPH_HEIGHT" \
		background.padding_left=3 \
		background.padding_right=5
}

status_pill() {
	local name="$1"
	local position="$2"
	local icon="$3"
	local label="$4"

	sketchybar --add item "$name" "$position" \
		--set "$name" \
		icon="$icon" \
		icon.padding_left=6 \
		icon.padding_right=3 \
		label="$label" \
		label.font="$FONT:Medium:12.0" \
		label.padding_left=0 \
		label.padding_right=7 \
		background.drawing=on \
		background.color="$STATUS_BG" \
		background.corner_radius="$STATUS_RADIUS" \
		background.height="$STATUS_HEIGHT"
}

popup_row() {
	local parent="$1"
	local name="$2"
	local icon="$3"
	local label="$4"

	sketchybar --add item "$name" "popup.$parent" \
		--set "$name" \
		icon="$icon" \
		label="$label" \
		background.padding_left=6 \
		background.padding_right=8
}
