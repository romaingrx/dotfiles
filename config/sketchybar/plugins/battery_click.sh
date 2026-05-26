#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/env.sh"
sketchybar_resolve_paths "$SCRIPT_DIR"

NAME=battery "$PLUGIN_DIR/battery.sh" --details
sketchybar --set battery popup.drawing=toggle
