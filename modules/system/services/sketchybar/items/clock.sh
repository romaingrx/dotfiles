#! /usr/bin/env bash

sketchybar --add item clock right \
           --set clock \
           icon=􀧞 \
           background.drawing=off \
           script="$PLUGIN_DIR/clock.sh" \
           update_freq=1
