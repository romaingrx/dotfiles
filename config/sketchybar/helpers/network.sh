#!/usr/bin/env bash

# macOS 26 removed the private Apple80211 `airport` binary, so SSID and link rate
# are no longer obtainable from a shell script:
#   - `airport -I`                      -> binary does not exist
#   - `ipconfig getsummary en0`         -> "SSID : <redacted>"
#   - `wdutil info`                     -> empty without root
#   - `networksetup -getairportnetwork` -> "You are not associated..."
# Reading the SSID now requires root or a Location Services entitlement, neither
# of which a sketchybar plugin has. The SSID/rate helpers were returning empty
# strings on every call; they are gone rather than silently broken. The wifi
# plugin's existing "Wi-Fi connected"/"Disconnected" fallback covers the display.

# The Wi-Fi device name does not change at runtime, but discovering it costs a
# `networksetup -listallhardwareports` fork (19.2 ms measured). Cache it.
network_wifi_interface() {
	local cache="${TMPDIR:-/tmp}/sketchybar-wifi-iface"
	local iface

	if [ -r "$cache" ]; then
		read -r iface <"$cache"
		if [ -n "$iface" ]; then
			printf "%s" "$iface"
			return
		fi
	fi

	iface="$(
		networksetup -listallhardwareports 2>/dev/null |
			awk '/Hardware Port: Wi-Fi/ { getline; print $2; exit }'
	)"
	[ -n "$iface" ] || return 1

	printf "%s\n" "$iface" >"$cache"
	printf "%s" "$iface"
}

network_local_ip() {
	local iface="${1:-}"

	[ -n "$iface" ] || iface="$(network_wifi_interface)"
	[ -n "$iface" ] || return 1

	ipconfig getifaddr "$iface" 2>/dev/null
}

network_vpn_name() {
	scutil --nc list 2>/dev/null | awk -F '"' '/\(Connected\)/ { print $2; exit }'
}

network_interface_bytes() {
	local iface="${1:-}"

	[ -n "$iface" ] || iface="$(network_wifi_interface)"
	[ -n "$iface" ] || return 1

	netstat -ibn 2>/dev/null |
		awk -v iface="$iface" '
			$1 == iface && $3 ~ /^<Link/ {
				in_bytes += $7
				out_bytes += $10
			}
			END {
				if (in_bytes == "" && out_bytes == "") exit 1
				printf "%s|%s", in_bytes + 0, out_bytes + 0
			}
		'
}

# Formats down/up into the four strings the bar needs in ONE awk instead of four
# (network_graph_value x2 + network_rate_label x2 was 4 forks per pass).
network_format_rates() {
	local down="${1:-0}" up="${2:-0}" cap="${3:-5242880}"

	awk -v down="$down" -v up="$up" -v cap="$cap" '
		function graph(b,   v) {
			if (b <= 0) return 0
			v = exp(log(b / cap) / 3)
			if (v < 0) v = 0
			if (v > 1) v = 1
			return sprintf("%.4f", v)
		}
		function label(b) {
			if (b >= 1048576) return sprintf("%.1fM/s", b / 1048576)
			if (b >= 1024) return sprintf("%.0fK/s", b / 1024)
			return sprintf("%.0fB/s", b)
		}
		BEGIN {
			# 5th field: which direction dominates. Computing it here saves the
			# callers a separate awk fork just to compare two floats.
			printf "%s|%s|%s|%s|%s", graph(down), graph(up), label(down), label(up),
				(up > down ? "up" : "down")
		}
	'
}

network_rates() {
	local iface="${1:-}"
	local now previous state_file in_bytes out_bytes
	local previous_ts previous_in previous_out elapsed down up

	[ -n "$iface" ] || iface="$(network_wifi_interface)"
	[ -n "$iface" ] || return 1

	IFS="|" read -r in_bytes out_bytes <<EOF
$(network_interface_bytes "$iface")
EOF
	[ -n "$in_bytes" ] && [ -n "$out_bytes" ] || return 1

	# $EPOCHSECONDS is a bash builtin; `date +%s` was a fork (1.7 ms) per pass.
	now="${EPOCHSECONDS:-$(date +%s)}"
	state_file="${TMPDIR:-/tmp}/sketchybar-network-$iface.state"

	if [ -r "$state_file" ]; then
		read -r previous_ts previous_in previous_out <"$state_file"
	fi

	printf "%s %s %s\n" "$now" "$in_bytes" "$out_bytes" >"$state_file"

	case "${previous_ts:-}" in
	"" | *[!0-9]*) previous_ts="$now" ;;
	esac
	case "${previous_in:-}" in
	"" | *[!0-9]*) previous_in="$in_bytes" ;;
	esac
	case "${previous_out:-}" in
	"" | *[!0-9]*) previous_out="$out_bytes" ;;
	esac

	elapsed=$((now - previous_ts))
	[ "$elapsed" -gt 0 ] || elapsed=1

	down=$(((in_bytes - previous_in) / elapsed))
	up=$(((out_bytes - previous_out) / elapsed))
	[ "$down" -ge 0 ] || down=0
	[ "$up" -ge 0 ] || up=0

	network_format_rates "$down" "$up"
}
