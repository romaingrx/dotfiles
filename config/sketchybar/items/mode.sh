#!/usr/bin/env bash

source "$HELPER_DIR/components.sh"

sketchybar --add event aerospace_mode_change

status_pill mode.indicator left "$LAYOUT_ICN" mode
sketchybar --set mode.indicator \
	drawing=off \
	updates=on \
	script="$PLUGIN_DIR/mode.sh" \
	update_freq=1 \
	click_script="sketchybar --set mode.indicator popup.drawing=toggle" \
	icon.color="$MAGENTA" \
	label.color="$MAGENTA" \
	background.color="$MODE_BG" \
	popup.background.color="$POPUP_BG" \
	popup.blur_radius=50 \
	popup.background.corner_radius=5 \
	popup.align=left \
	popup.height=26 \
	--subscribe mode.indicator aerospace_mode_change system_woke

popup_row mode.indicator mode.exit "$LAYOUT_ICN" "esc - reload config / main"
popup_row mode.indicator mode.flatten "$LAYOUT_ICN" "r - flatten workspace"
popup_row mode.indicator mode.float "$WINDOW_ICN" "f - floating / tiling"
popup_row mode.indicator mode.close "$WINDOW_ICN" "backspace - close others"
popup_row mode.indicator mode.join "$WINDOW_ICN" "shift + hjkl - join windows"
popup_row mode.indicator mode.monitor "$WINDOW_ICN" "alt + 1/2/3/B/C - move to monitor"
