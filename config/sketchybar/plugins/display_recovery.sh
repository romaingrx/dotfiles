#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/env.sh"
sketchybar_resolve_paths "$SCRIPT_DIR"

source "$HELPER_DIR/sketchybar.sh"
source "$HELPER_DIR/aerospace.sh"

case "${SENDER:-}" in
display_change | system_woke) ;;
*) exit 0 ;;
esac

delay="${SKETCHYBAR_DISPLAY_RECOVERY_DELAY:-1}"
stamp_file="${TMPDIR:-/tmp}/sketchybar-display-recovery.stamp"

(
	sleep "$delay"

	if sketchybar_has_placeholder_display; then
		sketchybar_debounced_kickstart "$stamp_file"
		exit 0
	fi

	aerospace_trigger_workspace_change
) >/dev/null 2>&1 &
