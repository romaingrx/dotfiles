#!/usr/bin/env bash

# status_item NAME [ARG...]: a right-side item with the bar's spacing and type,
# then ARGs (more properties, or --subscribe and the like).
status_item() {
	local name="$1"
	shift

	sketchybar --add item "$name" right \
		--set "$name" \
		padding_left="$STATUS_GAP" \
		padding_right="$STATUS_GAP" \
		icon.padding_left=0 \
		icon.padding_right=6 \
		label.font="$FONT:Medium:13.0" \
		label.padding_left=0 \
		label.padding_right=0 \
		"$@"
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
