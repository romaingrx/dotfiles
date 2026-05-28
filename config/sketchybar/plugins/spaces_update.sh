#!/usr/bin/env bash

# Entry point for the spaces_controller item (subscribed to workspace/monitor
# events and run on init).
#
# Fast path: a plain workspace switch only changes the focus state of two
# indicators, and AeroSpace already hands us FOCUSED_WORKSPACE and
# PREV_WORKSPACE. So repaint just those two with ZERO queries (instant), then
# kick a full reconcile in the background to fix what we can't know without
# querying (multi-monitor PREV visibility, empty-vs-occupied shade, and labels
# after move-node-to-workspace). Any wrong optimistic guess for PREV -- one that
# is still visible on another monitor -- corrects within a frame, and that flash
# is on the monitor you just left, not the one you moved to.
#
# Any other sender (init/forced paint, aerospace_monitor_change) goes straight to
# the authoritative full repaint.
#
# This stays query-free on purpose: it sources only colors + sketchybar (not the
# heavy aerospace/display helpers), and never shells out to aerospace/jq/query.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/env.sh"
sketchybar_resolve_paths "$SCRIPT_DIR"
source "$CONFIG_DIR/colors.sh"
source "$HELPER_DIR/sketchybar.sh"

if [ "$SENDER" = "aerospace_workspace_change" ] && [ -n "${FOCUSED_WORKSPACE:-}" ]; then
	focused="$FOCUSED_WORKSPACE"
	prev="${PREV_WORKSPACE:-}"
	sb="$(sketchybar_bin)"

	if [ -n "$sb" ]; then
		# Focused workspace -> highlighted.
		args=(--set "space.$focused"
			background.color=0x55ffffff
			background.drawing=on
			icon.color="$WHITE"
			label.color="$WHITE")

		# Previous workspace -> optimistically un-highlighted (assume it is now
		# hidden, the common same-monitor case). Reconcile fixes the rest.
		if [ -n "$prev" ] && [ "$prev" != "$focused" ]; then
			args+=(--set "space.$prev"
				background.drawing=off
				icon.color="$WHITE"
				label.color="$GREY")
		fi

		"$sb" "${args[@]}"
	fi

	# Authoritative reconcile, fully detached so it never blocks the highlight.
	( SENDER=aerospace_workspace_change "$PLUGIN_DIR/spaces_reconcile.sh" >/dev/null 2>&1 & )
	exit 0
fi

exec "$PLUGIN_DIR/spaces_reconcile.sh"
