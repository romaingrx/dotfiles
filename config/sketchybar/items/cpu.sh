#!/usr/bin/env bash

source "$HELPER_DIR/components.sh"

sketchybar --add graph cpu.sys right 1 \
	--set cpu.sys \
	drawing=off \
	graph.color="$RED" \
	graph.fill_color=0x20ed8796 \
	label.drawing=off \
	icon.drawing=off

status_graph cpu.user right "$BLUE" 0x208aadf4
sketchybar --set cpu.user \
	label=0% \
	update_freq=2 \
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
