#!/usr/bin/env bash

# Slow path: drives wifi.control and its popup rows (update_freq=30).
# The net.activity graph now has its own fast plugin (plugins/net_activity.sh);
# this script no longer touches it.
#
# SSID and link rate are deliberately absent — see helpers/network.sh. They were
# read via the private `airport -I`, which macOS 26 removed, so both rows had
# been rendering empty on every pass.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/env.sh"
sketchybar_resolve_paths "$SCRIPT_DIR"

source "$CONFIG_DIR/colors.sh" || exit 1
source "$CONFIG_DIR/icons.sh"
source "$HELPER_DIR/app_icons.sh"
source "$HELPER_DIR/network.sh"
source "$HELPER_DIR/text.sh"

iface="$(network_wifi_interface || true)"
ip="$(network_local_ip "$iface" || true)"
vpn="$(network_vpn_name || true)"

wifi_icon_color="$WHITE"
wifi_label=""
wifi_label_drawing=off
ssid_label="Disconnected"
ip_label="No IP"
vpn_label="VPN off"
vpn_color="$GREY"
vpn_icon="$VPN_ICN"
vpn_icon_font="$NERD_FONT:Regular:12.0"

if [ -n "$iface" ] && [ -n "$ip" ]; then
	ip_label="$iface: $ip"
	ssid_label="Wi-Fi connected"
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

sketchybar --set wifi.control \
	icon="$WIFI_ICN" \
	icon.color="$wifi_icon_color" \
	label="$wifi_label" \
	label.font="$vpn_icon_font" \
	label.color="$vpn_color" \
	label.drawing="$wifi_label_drawing" \
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
	label="$ip_label"
