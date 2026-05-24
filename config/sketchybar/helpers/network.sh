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
