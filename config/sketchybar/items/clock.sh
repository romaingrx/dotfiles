#!/usr/bin/env bash

sketchybar --add item clock right \
	--set clock \
	update_freq=15 \
	padding_left=7 \
	padding_right=0 \
	script="$PLUGIN_DIR/clock.sh"
