#!/usr/bin/env sh

sketchybar --add item cpu.percent right \
	--set cpu.percent \
	label.font="$FONT:Bold:12" \
	label=CPU \
	width=36 \
	icon.drawing=off \
	update_freq=2 \
	click_script="sketchybar --set cpu.percent popup.drawing=toggle" \
	background.drawing=on \
	background.color="$STATUS_BG" \
	background.corner_radius="$STATUS_RADIUS" \
	background.height="$STATUS_HEIGHT" \
	background.padding_left=5 \
	background.padding_right=5 \
	popup.background.color=0x70000000 \
	popup.blur_radius=50 \
	popup.background.corner_radius=5 \
	popup.align=right \
	popup.height=26 \
	\
	--add item cpu.top popup.cpu.percent \
	--set cpu.top \
	label.font="$FONT:Medium:12" \
	label=CPU \
	icon.drawing=off \
	background.padding_left=6 \
	background.padding_right=8 \
	\
	--add graph cpu.sys right 1 \
	--set cpu.sys \
	drawing=off \
	graph.color=$RED \
	graph.fill_color=0x20ed8796 \
	label.drawing=off \
	icon.drawing=off \
	\
	--add graph cpu.user right 42 \
	--set cpu.user \
	graph.color=$BLUE \
	graph.fill_color=0x208aadf4 \
	graph.line_width=0.8 \
	update_freq=2 \
	label.drawing=off \
	icon.drawing=off \
	background.drawing=on \
	background.color="$STATUS_GRAPH_BG" \
	background.corner_radius="$STATUS_RADIUS" \
	background.height=18 \
	background.padding_left=3 \
	background.padding_right=5 \
	script="$PLUGIN_DIR/cpu.sh"
