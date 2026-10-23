#!/usr/bin/env bash

sketchybar --add item clock center \
	--set clock \
	update_freq=15 \
	script="$PLUGIN_DIR/clock.sh"
