#!/usr/bin/env sh

sketchybar --add item cpu.percent right \
	--set cpu.percent \
	label.font="$FONT:Bold:12" \
	label=CPU \
	width=34 \
	icon.drawing=off \
	update_freq=2 \
	click_script="sketchybar --set cpu.percent popup.drawing=toggle" \
	background.drawing=on \
	background.color=0x22000000 \
	background.corner_radius=6 \
	background.height=22 \
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
	--add graph cpu.sys right 56 \
	--set cpu.sys \
	width=0 \
	graph.color=$RED \
	graph.fill_color=0x30ed8796 \
	label.drawing=off \
	icon.drawing=off \
	background.padding_right=2 \
	\
	--add graph cpu.user right 56 \
	--set cpu.user \
	graph.color=$BLUE \
	graph.fill_color=0x308aadf4 \
	update_freq=2 \
	label.drawing=off \
	icon.drawing=off \
	background.padding_right=6 \
	script="$PLUGIN_DIR/cpu.sh"
