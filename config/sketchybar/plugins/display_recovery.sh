#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/env.sh"
sketchybar_resolve_paths "$SCRIPT_DIR"

source "$HELPER_DIR/sketchybar.sh"
source "$HELPER_DIR/display_map.sh"
source "$HELPER_DIR/aerospace.sh"

case "${SENDER:-}" in
display_change | system_woke) ;;
*) exit 0 ;;
esac

delay="${SKETCHYBAR_DISPLAY_RECOVERY_DELAY:-1}"
attempts="${SKETCHYBAR_DISPLAY_RECOVERY_ATTEMPTS:-4}"
interval="${SKETCHYBAR_DISPLAY_RECOVERY_INTERVAL:-1}"
stamp_file="${TMPDIR:-/tmp}/sketchybar-display-recovery.stamp"

(
	sleep "$delay"

	i=1
	while [ "$i" -le "$attempts" ]; do
		sketchybar_count="$(sketchybar_valid_display_count)"
		aerospace_count="$(aerospace_monitor_count)"

		if [ "$sketchybar_count" -gt 0 ] &&
			{ [ "$aerospace_count" -eq 0 ] || [ "$sketchybar_count" -eq "$aerospace_count" ]; }; then
			display_map_refresh || exit 0
			aerospace_trigger_monitor_change
			aerospace_trigger_workspace_change
			exit 0
		fi

		i=$((i + 1))
		sleep "$interval"
	done

	display_map_invalidate
	sketchybar_debounced_kickstart "$stamp_file"
) >/dev/null 2>&1 &
