#!/usr/bin/env bash

sketchybar --add graph cpu.sys right 1 \
	--set cpu.sys \
	drawing=off \
	graph.color="$RED" \
	graph.fill_color=0x20ed8796 \
	label.drawing=off \
	icon.drawing=off \
	\
	--add graph cpu.user right "$STATUS_GRAPH_WIDTH" \
	--set cpu.user \
	graph.color="$BLUE" \
	graph.fill_color=0x208aadf4 \
	graph.line_width=0.8 \
	label=0% \
	label.drawing=on \
	label.font="$FONT:Medium:9.0" \
	label.color="$BLUE" \
	label.width="$STATUS_GRAPH_LABEL_WIDTH" \
	label.align=right \
	label.padding_left=2 \
	label.padding_right=3 \
	update_freq=2 \
	icon.drawing=off \
	background.drawing=on \
	background.color="$STATUS_GRAPH_BG" \
	background.corner_radius="$STATUS_RADIUS" \
	background.height=18 \
	background.padding_left=3 \
	background.padding_right=5 \
	script="$PLUGIN_DIR/cpu.sh" \
	click_script="sketchybar --set cpu.user popup.drawing=toggle" \
	popup.background.color=0x70000000 \
	popup.blur_radius=50 \
	popup.background.corner_radius=5 \
	popup.align=right \
	popup.height=26 \
	\
	--add item cpu.top popup.cpu.user \
	--set cpu.top \
	label.font="$FONT:Medium:12" \
	label=CPU \
	icon.drawing=off \
	background.padding_left=6 \
	background.padding_right=8
