#!/usr/bin/env bash

# Shows a stats item's history popup while the pointer is on it.

case "$SENDER" in
mouse.entered) sketchybar --set "$NAME" popup.drawing=on ;;
mouse.exited | mouse.exited.global) sketchybar --set "$NAME" popup.drawing=off ;;
esac
