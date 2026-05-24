#!/usr/bin/env bash

network_airport_bin() {
	printf "%s" "/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
}

network_wifi_info() {
	local airport

	airport="$(network_airport_bin)"
	[ -x "$airport" ] || return 1
	"$airport" -I 2>/dev/null
}

network_wifi_ssid() {
	network_wifi_info | awk -F ": " '/ SSID/ { print $2; exit }'
}

network_wifi_rate() {
	network_wifi_info | awk -F ": " '/lastTxRate/ { print $2; exit }'
}

network_wifi_interface() {
	networksetup -listallhardwareports 2>/dev/null |
		awk '/Hardware Port: Wi-Fi/ { getline; print $2; exit }'
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

network_rate_label() {
	local bytes="${1:-0}"

	awk -v bytes="$bytes" '
		BEGIN {
			if (bytes >= 1048576) printf "%.1fM/s", bytes / 1048576
			else if (bytes >= 1024) printf "%.0fK/s", bytes / 1024
			else printf "%.0fB/s", bytes
		}
	'
}

network_graph_value() {
	local bytes="${1:-0}"
	local cap="${2:-5242880}"

	awk -v bytes="$bytes" -v cap="$cap" '
		BEGIN {
			if (bytes <= 0) value = 0
			else value = exp(log(bytes / cap) / 3)
			if (value < 0) value = 0
			if (value > 1) value = 1
			printf "%.4f", value
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

	now="$(date +%s)"
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

	printf "%s|%s|%s|%s" \
		"$(network_graph_value "$down")" \
		"$(network_graph_value "$up")" \
		"$(network_rate_label "$down")" \
		"$(network_rate_label "$up")"
}
