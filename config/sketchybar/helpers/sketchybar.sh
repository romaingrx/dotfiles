#!/usr/bin/env bash

sketchybar_bin() {
	local candidate

	for candidate in "${SKETCHYBAR_BIN:-}" \
		/run/current-system/sw/bin/sketchybar \
		/opt/homebrew/bin/sketchybar \
		/usr/local/bin/sketchybar; do
		if [ -n "$candidate" ] && [ -x "$candidate" ]; then
			printf "%s" "$candidate"
			return
		fi
	done

	command -v sketchybar 2>/dev/null
}

sketchybar_query() {
	local bin

	bin="$(sketchybar_bin)"
	[ -n "$bin" ] || return 1

	"$bin" --query "$@" 2>/dev/null
}

sketchybar_has_placeholder_display() {
	local jq_bin displays

	jq_bin="$(command -v jq 2>/dev/null || true)"
	[ -n "$jq_bin" ] || return 1

	displays="$(sketchybar_query displays || true)"
	[ -n "$displays" ] || return 1

	printf "%s" "$displays" |
		"$jq_bin" -e '.[] | select(.DirectDisplayID == 0 or .["arrangement-id"] == 0)' >/dev/null 2>&1
}

sketchybar_kickstart() {
	local user_id

	user_id="$(/usr/bin/id -u 2>/dev/null || true)"
	[ -n "$user_id" ] || return 1

	/bin/launchctl kickstart -k "gui/$user_id/org.nixos.sketchybar" >/dev/null 2>&1
}

sketchybar_debounced_kickstart() {
	local stamp_file="${1:-${TMPDIR:-/tmp}/sketchybar-display-recovery.stamp}"
	local min_interval="${SKETCHYBAR_DISPLAY_RECOVERY_MIN_INTERVAL:-8}"
	local now last

	now="$(/bin/date +%s)"
	last="$(cat "$stamp_file" 2>/dev/null || printf "0")"

	case "$last" in
	"" | *[!0-9]*) last=0 ;;
	esac

	if [ $((now - last)) -lt "$min_interval" ]; then
		return 0
	fi

	printf "%s" "$now" >"$stamp_file"
	sketchybar_kickstart
}
