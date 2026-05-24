#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/env.sh"
sketchybar_resolve_paths "$SCRIPT_DIR"

osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to not dark mode'

"$CONFIG_DIR/plugins/darkmode.sh"
