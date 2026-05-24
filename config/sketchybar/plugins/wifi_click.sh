#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/env.sh"
sketchybar_resolve_paths "$SCRIPT_DIR"

NAME=wifi.control "$PLUGIN_DIR/wifi.sh"
sketchybar --set wifi.control popup.drawing=toggle
