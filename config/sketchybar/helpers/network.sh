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
