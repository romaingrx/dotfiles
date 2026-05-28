#!/usr/bin/env bash

# Authoritative full repaint of every AeroSpace workspace indicator.
#
# This is the slow-but-correct path. It runs:
#   - synchronously for init/forced paint and for aerospace_monitor_change
#     (display assignments may have changed), and
#   - in the background after a plain workspace switch, to reconcile whatever the
#     instant 2-set in spaces_update.sh could not know without querying:
#     multi-monitor PREV visibility, empty-vs-occupied icon shade, and app-icon
#     labels (which change when move-node-to-workspace fires this same event).
#
# It derives the whole picture in two queries and repaints in one batched
# `sketchybar --set`. Popups are intentionally not built here (space_click.sh
# rebuilds the popup when it is opened).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/env.sh"
sketchybar_resolve_paths "$SCRIPT_DIR"

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"
source "$HELPER_DIR/aerospace.sh"
source "$HELPER_DIR/app_icons.sh"
source "$HELPER_DIR/display_map.sh"

MAX_WORKSPACE_APPS="${MAX_WORKSPACE_APPS:-4}"
AEROSPACE_FALLBACK_WORKSPACES="${AEROSPACE_FALLBACK_WORKSPACES:-1 2 3 B C M U S}"

# Only used to seed focus in the synthesized fallback below; the real repaint
# reads focus from each workspace's own query flag, never from this env value.
event_focused="${FOCUSED_WORKSPACE:-}"

# Display assignment only changes when a workspace moves monitors (or at init),
# never on a plain workspace switch. Resolving it costs osascript/jq/sketchybar
# queries, so skip it on the hot switch path and only recompute otherwise.
do_display=1
[ "$SENDER" = "aerospace_workspace_change" ] && do_display=0

# One call: full state for every workspace.
state_all="$(aerospace_query list-workspaces --all \
	--format "%{workspace}|%{workspace-is-focused}|%{workspace-is-visible}|%{monitor-appkit-nsscreen-screens-id}")"

# One call: every window, grouped later by workspace (labels + counts).
windows_all="$(aerospace_query list-windows --all \
	--format "%{workspace}|%{app-name}|%{app-bundle-id}")"

# If the server didn't answer, synthesize a minimal state so the bar still paints.
if [ -z "$state_all" ]; then
	for ws in $AEROSPACE_FALLBACK_WORKSPACES; do
		f="false"
		[ "$ws" = "$event_focused" ] && f="true"
		state_all="${state_all}${ws}|${f}|${f}|
"
	done
fi

# Memo of appkit-screen-id -> sketchybar display (tab-separated lines), so we
# resolve each distinct monitor at most once instead of per-workspace.
display_memo=""

resolve_display() {
	local appkit="$1"
	local hit d

	[ -n "$appkit" ] || return 1

	hit="$(printf "%s" "$display_memo" | awk -F'\t' -v k="$appkit" '$1==k{print $2; exit}')"
	if [ -n "$hit" ]; then
		[ "$hit" = "-" ] && return 1
		printf "%s" "$hit"
		return 0
	fi

	d="$(display_map_sketchybar_display_for_appkit_screen_id "$appkit" 2>/dev/null || true)"
	if [ -n "$d" ]; then
		display_memo="${display_memo}${appkit}	${d}
"
		printf "%s" "$d"
		return 0
	fi

	display_memo="${display_memo}${appkit}	-
"
	return 1
}

workspace_window_count() {
	printf "%s\n" "$windows_all" |
		awk -F"|" -v ws="$1" '$1==ws && $2!="" {c++} END{print c+0}'
}

workspace_label() {
	local workspace="$1"
	local app bundle icons count total
	icons=""
	count=0
	total=0

	while IFS="|" read -r app bundle; do
		[ -n "$app" ] || continue
		total=$((total + 1))
		if [ "$count" -lt "$MAX_WORKSPACE_APPS" ]; then
			icons="${icons}${icons:+ }$(app_ligature "$bundle" "$app")"
			count=$((count + 1))
		fi
	done <<EOF
$(printf "%s\n" "$windows_all" | awk -F"|" -v ws="$workspace" '$1==ws && $2!="" && !seen[$2"|"$3]++ {print $2"|"$3}')
EOF

	if [ "$total" -gt "$MAX_WORKSPACE_APPS" ]; then
		icons="$icons +$((total - MAX_WORKSPACE_APPS))"
	fi

	printf "%s" "$icons"
}

args=()
while IFS="|" read -r ws is_focused is_visible appkit; do
	[ -n "$ws" ] || continue

	wlabel="$(workspace_label "$ws")"
	wcount="$(workspace_window_count "$ws")"

	# Focus comes from the query's own flag (current real state), NOT the
	# inherited FOCUSED_WORKSPACE env, so an async reconcile that lands after
	# several rapid switches still paints the latest truth rather than a stale
	# event's focused workspace.
	icon_color="$WHITE"
	label_color="$GREY"
	background_color="$TRANSPARENT"
	background_drawing="off"
	label_drawing="on"
	[ -n "$wlabel" ] || label_drawing="off"

	if [ "$is_focused" = "true" ]; then
		icon_color="$WHITE"
		label_color="$WHITE"
		background_color=0x55ffffff
		background_drawing="on"
	elif [ "$is_visible" = "true" ]; then
		icon_color="$BLUE"
		label_color="$WHITE"
		background_color=0x22ffffff
		background_drawing="on"
	elif [ "$wcount" -eq 0 ]; then
		icon_color="$GREY"
		label_color="$GREY"
	fi

	args+=(--set "space.$ws" drawing=on)
	if [ "$do_display" = "1" ]; then
		d="$(resolve_display "$appkit" || true)"
		[ -n "$d" ] && args+=(display="$d")
	fi
	args+=(
		icon="$ws"
		icon.color="$icon_color"
		label="$wlabel"
		label.color="$label_color"
		label.drawing="$label_drawing"
		background.color="$background_color"
		background.drawing="$background_drawing"
	)
done <<EOF
$state_all
EOF

if [ "${#args[@]}" -gt 0 ]; then
	sb="$(sketchybar_bin)"
	[ -n "$sb" ] && "$sb" "${args[@]}"
fi
