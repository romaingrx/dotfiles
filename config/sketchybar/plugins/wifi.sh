#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/env.sh"
sketchybar_resolve_paths "$SCRIPT_DIR"

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"
source "$HELPER_DIR/network.sh"
source "$HELPER_DIR/text.sh"

ssid="$(network_wifi_ssid)"
rate="$(network_wifi_rate)"
iface="$(network_wifi_interface)"
ip="$(network_local_ip "$iface")"
vpn="$(network_vpn_name)"
rates="$(network_rates "$iface" || true)"
IFS="|" read -r down_graph up_graph down_label up_label <<EOF
$rates
EOF

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
down_graph="${down_graph:-0}"
up_graph="${up_graph:-0}"
down_label="${down_label:-0B/s}"
up_label="${up_label:-0B/s}"

if [ -n "$iface" ] && [ -n "$ip" ]; then
	ip_label="$iface: $ip"
	if [ -z "$ssid" ]; then
		ssid_label="Wi-Fi connected"
	fi
else
	wifi_icon_color="$GREY"
fi

if [ -n "$vpn" ]; then
	wifi_label="$VPN_ICN"
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
	--push net.down "$down_graph" \
	--push net.up "$up_graph" \
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
	label="$rate_label - down $down_label - up $up_label"
