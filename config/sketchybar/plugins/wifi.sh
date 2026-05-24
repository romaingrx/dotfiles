#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${CONFIG_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
HELPER_DIR="${HELPER_DIR:-$CONFIG_DIR/helpers}"

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"
source "$HELPER_DIR/network.sh"
source "$HELPER_DIR/text.sh"

ssid="$(network_wifi_ssid)"
rate="$(network_wifi_rate)"
iface="$(network_wifi_interface)"
ip="$(network_local_ip "$iface")"
vpn="$(network_vpn_name)"

wifi_icon_color="$WHITE"
wifi_label=""
wifi_label_drawing=off
ssid_label="${ssid:-Disconnected}"
if [ -z "$rate" ]; then
	rate="--"
fi
rate_label="$rate Mbps"
ip_label="No IP"
vpn_label="VPN off"
vpn_color="$GREY"

if [ -z "$ssid" ]; then
	wifi_icon_color="$RED"
fi

if [ -n "$iface" ] && [ -n "$ip" ]; then
	ip_label="$iface: $ip"
fi

if [ -n "$vpn" ]; then
	wifi_label="VPN"
	wifi_label_drawing=on
	vpn_label="$(text_truncate "$vpn" 32)"
	vpn_color="$GREEN"
fi

sketchybar --set wifi.control \
	icon="$WIFI_ICN" \
	icon.color="$wifi_icon_color" \
	label="$wifi_label" \
	label.color="$vpn_color" \
	label.drawing="$wifi_label_drawing" \
	--set wifi.ssid \
	icon="$NETWORK_ICN" \
	label="$ssid_label" \
	--set wifi.vpn \
	icon="$VPN_ICN" \
	icon.color="$vpn_color" \
	label="$vpn_label" \
	--set wifi.ip \
	icon="$IP_ICN" \
	label="$ip_label" \
	--set wifi.speed \
	icon="$SPEED_ICN" \
	label="$rate_label"
