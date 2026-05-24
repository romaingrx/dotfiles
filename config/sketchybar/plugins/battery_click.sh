#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${CONFIG_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
PLUGIN_DIR="${PLUGIN_DIR:-$CONFIG_DIR/plugins}"

NAME=battery "$PLUGIN_DIR/battery.sh" --details
sketchybar --set battery popup.drawing=toggle
