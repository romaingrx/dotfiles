#!/bin/sh

# Define colors
BACKGROUND_COLOR="0x44000000"
LABEL_COLOR="0xffffffff"       # White text
ICON_COLOR="0xffffffff"        # White icon

sketchybar --add item memory right \
           --set memory \
           update_freq=2 \
           icon="􀫦" \
           icon.color=$ICON_COLOR \
           icon.padding_right=8 \
           label.color=$LABEL_COLOR \
           label.padding_right=10 \
           label.width=40 \
           label.align=right \
           background.color=$BACKGROUND_COLOR \
           background.height=24 \
           background.corner_radius=11 \
           background.padding_left=7 \
           background.padding_right=7 \
           background.drawing=on \
           script="$PLUGIN_DIR/memory.sh" 