#!/usr/bin/env bash

AEROSPACE_FALLBACK_WORKSPACES="${AEROSPACE_FALLBACK_WORKSPACES:-1 2 3 B C M U S}"

aerospace_query() {
	command -v aerospace >/dev/null 2>&1 || return 1
	aerospace "$@" 2>/dev/null
}

aerospace_workspaces() {
	local workspaces

	workspaces="$(aerospace_query list-workspaces --all || true)"
	if [ -n "$workspaces" ]; then
		printf "%s\n" "$workspaces"
		return
	fi

	printf "%s\n" "$AEROSPACE_FALLBACK_WORKSPACES" | tr " " "\n"
}

aerospace_focused_workspace() {
	if [ -n "${FOCUSED_WORKSPACE:-}" ]; then
		printf "%s" "$FOCUSED_WORKSPACE"
		return
	fi

	aerospace_query list-workspaces --focused || true
}

aerospace_workspace_state() {
	local workspace="$1"
	local state

	state="$(
		aerospace_query list-workspaces --all \
			--format "%{workspace}|%{workspace-is-focused}|%{workspace-is-visible}|%{monitor-appkit-nsscreen-screens-id}|%{workspace-root-container-layout}" |
			awk -F "|" -v workspace="$workspace" '$1 == workspace { print; exit }'
	)"

	if [ -n "$state" ]; then
		printf "%s" "$state"
		return
	fi

	local focused="false"
	if [ "$(aerospace_focused_workspace)" = "$workspace" ]; then
		focused="true"
	fi

	printf "%s|%s|%s|%s|%s" "$workspace" "$focused" "$focused" "1" ""
}

aerospace_workspace_window_count() {
	local workspace="$1"
	local count

	count="$(aerospace_query list-windows --workspace "$workspace" --count || true)"
	case "$count" in
	"" | *[!0-9]*) printf "0" ;;
	*) printf "%s" "$count" ;;
	esac
}

aerospace_workspace_windows() {
	local workspace="$1"

	aerospace_query list-windows --workspace "$workspace" \
		--format "%{window-id}|%{app-name}|%{app-bundle-id}|%{window-title}" ||
		true
}

aerospace_workspace_apps() {
	local workspace="$1"

	aerospace_workspace_windows "$workspace" |
		awk -F "|" '$2 != "" && !seen[$2 "|" $3]++ { print $2 "|" $3 }'
}

aerospace_trigger_workspace_change() {
	local focused

	focused="$(aerospace_focused_workspace)"
	sketchybar --trigger aerospace_workspace_change \
		FOCUSED_WORKSPACE="${focused:-${1:-}}" \
		PREV_WORKSPACE="${PREV_WORKSPACE:-}"
}
