#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/env.sh"
sketchybar_resolve_paths "$SCRIPT_DIR"

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"
source "$HELPER_DIR/app_icons.sh"
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
vpn_icon="$VPN_ICN"
vpn_icon_font="$NERD_FONT:Regular:12.0"
down_graph="${down_graph:-0}"
up_graph="${up_graph:-0}"
down_label="${down_label:-0B/s}"
up_label="${up_label:-0B/s}"
activity_graph="$down_graph"
activity_label="↓${down_label%/s}"
activity_color="$BLUE"
activity_fill_color=0x208aadf4

if [ -n "$iface" ] && [ -n "$ip" ]; then
	ip_label="$iface: $ip"
	if [ -z "$ssid" ]; then
		ssid_label="Wi-Fi connected"
	fi
else
	wifi_icon_color="$GREY"
fi

if [ -n "$vpn" ]; then
	vpn_icon="$(app_icon "" "$vpn")"
	if [ "$vpn_icon" = ":default:" ]; then
		vpn_icon="$VPN_ICN"
	else
		vpn_icon_font="$APP_FONT:Regular:12.0"
	fi
	wifi_label="$vpn_icon"
	wifi_label_drawing=on
	vpn_label="$(text_truncate "$vpn" 32)"
	vpn_color="$GREEN"
fi

if awk -v down="$down_graph" -v up="$up_graph" 'BEGIN { exit !(up > down) }'; then
	activity_graph="$up_graph"
	activity_label="↑${up_label%/s}"
	activity_color="$GREEN"
	activity_fill_color=0x20a6da95
fi

sketchybar --set wifi.control \
	icon="$WIFI_ICN" \
	icon.color="$wifi_icon_color" \
	label="$wifi_label" \
	label.font="$vpn_icon_font" \
	label.color="$vpn_color" \
	label.drawing="$wifi_label_drawing" \
	--set net.activity \
	label="$activity_label" \
	label.color="$activity_color" \
	graph.color="$activity_color" \
	graph.fill_color="$activity_fill_color" \
	--push net.activity "$activity_graph" \
	--set wifi.ssid \
	icon="$NETWORK_ICN" \
	label="$ssid_label" \
	--set wifi.vpn \
	icon="$vpn_icon" \
	icon.font="$vpn_icon_font" \
	icon.color="$vpn_color" \
	label="$vpn_label" \
	--set wifi.ip \
	icon="$IP_ICN" \
	label="$ip_label" \
	--set wifi.speed \
	icon="$SPEED_ICN" \
	label="$rate_label - down $down_label / up $up_label"
