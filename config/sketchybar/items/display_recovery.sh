#!/usr/bin/env bash

sketchybar --add item display.recovery center \
	--set display.recovery \
	drawing=off \
	updates=on \
	script="$PLUGIN_DIR/display_recovery.sh" \
	--subscribe display.recovery display_change system_woke
