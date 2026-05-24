#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/env.sh"
sketchybar_resolve_paths "$SCRIPT_DIR"

source "$HELPER_DIR/aerospace.sh"

workspace="$1"
button="${BUTTON:-left}"
modifier="${MODIFIER:-}"
item="space.$workspace"

refresh_workspace() {
	NAME="$item" "$PLUGIN_DIR/space.sh"
}

case "$modifier:$button" in
":right")
	refresh_workspace
	sketchybar --set "$item" popup.drawing=toggle
	;;
"shift:left")
	aerospace_query move-node-to-workspace --focus-follows-window "$workspace" || true
	aerospace_trigger_workspace_change "$workspace"
	;;
"alt:left")
	aerospace_query move-workspace-to-monitor --workspace "$workspace" --wrap-around next || true
	sketchybar --trigger aerospace_monitor_change \
		TARGET_MONITOR="$(aerospace_query list-monitors --focused --format "%{monitor-appkit-nsscreen-screens-id}" || true)" \
		FOCUSED_WORKSPACE="$(aerospace_focused_workspace)"
	;;
"cmd:left")
	aerospace_query summon-workspace "$workspace" || true
	aerospace_trigger_workspace_change "$workspace"
	;;
*)
	aerospace_query workspace "$workspace" || true
	aerospace_trigger_workspace_change "$workspace"
	;;
esac
