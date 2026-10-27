#!/usr/bin/env bash

sketchybar --add item clock right \
	--set clock \
	update_freq=15 \
	padding_left=7 \
	script="$PLUGIN_DIR/clock.sh"
