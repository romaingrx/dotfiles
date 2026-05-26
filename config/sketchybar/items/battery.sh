#!/usr/bin/env bash

sketchybar --add item battery right \
	--set battery \
	icon.padding_left=5 \
	icon.padding_right=3 \
	label.font="$FONT:Medium:12.0" \
	label.padding_left=0 \
	label.padding_right=6 \
	script="$PLUGIN_DIR/battery.sh" \
	update_freq=30 \
	click_script="$PLUGIN_DIR/battery_click.sh" \
	background.drawing=on \
	background.color="$STATUS_BG" \
	background.corner_radius="$STATUS_RADIUS" \
	background.height="$STATUS_HEIGHT" \
	popup.background.color=0x70000000 \
	popup.blur_radius=50 \
	popup.background.corner_radius=5 \
	popup.align=right \
	popup.height=26 \
	--subscribe battery system_woke power_source_change

sketchybar --add item battery.source popup.battery \
	--set battery.source \
	icon="$POWER_ICN" \
	label="Power source" \
	background.padding_left=6 \
	background.padding_right=8

sketchybar --add item battery.time popup.battery \
	--set battery.time \
	icon="$CLOCK_ICN" \
	label="Time remaining" \
	background.padding_left=6 \
	background.padding_right=8

sketchybar --add item battery.health popup.battery \
	--set battery.health \
	icon="$HEALTH_ICN" \
	label="Health" \
	background.padding_left=6 \
	background.padding_right=8

sketchybar --add item battery.cycles popup.battery \
	--set battery.cycles \
	icon="$BATTERY_100" \
	label="Cycles" \
	background.padding_left=6 \
	background.padding_right=8
