#!/usr/bin/env bash

# The Tailscale logo from sketchybar-app-font, lit while connected.
sketchybar --add item tailscale right \
	--set tailscale \
	icon=":tailscale:" \
	icon.font="$APP_FONT:Regular:14.0" \
	icon.color="$THEME_MUTED" \
	icon.padding_left=0 \
	icon.padding_right=0 \
	label.drawing=off \
	padding_left=8 \
	padding_right=7 \
	script="$PLUGIN_DIR/tailscale.sh" \
	update_freq=10 \
	--subscribe tailscale system_woke wifi_change

sketchybar --add item wifi.control right \
	--set wifi.control \
	icon="$WIFI_ICN" \
	icon.padding_left=0 \
	icon.padding_right=0 \
	label.font="$APP_FONT:Regular:12.0" \
	label.padding_left=6 \
	label.padding_right=0 \
	label.drawing=off \
	script="$PLUGIN_DIR/wifi.sh" \
	update_freq=30 \
	click_script="$PLUGIN_DIR/wifi_click.sh" \
	padding_left=7 \
	padding_right=0 \
	popup.background.color="$POPUP_BG" \
	popup.blur_radius=50 \
	popup.background.corner_radius=5 \
	popup.align=right \
	popup.height=26 \
	--subscribe wifi.control system_woke wifi_change

sketchybar --add item wifi.ssid popup.wifi.control \
	--set wifi.ssid \
	icon="$NETWORK_ICN" \
	label="Disconnected" \
	background.padding_left=6 \
	background.padding_right=8

sketchybar --add item wifi.vpn popup.wifi.control \
	--set wifi.vpn \
	icon="$VPN_ICN" \
	label="VPN off" \
	background.padding_left=6 \
	background.padding_right=8

sketchybar --add item wifi.ip popup.wifi.control \
	--set wifi.ip \
	icon="$IP_ICN" \
	label="No IP" \
	background.padding_left=6 \
	background.padding_right=8

# wifi.speed removed: it displayed the Wi-Fi link rate from `airport -I`, which
# macOS 26 deleted. It has been rendering "-- Mbps" ever since, and the rate is
# not obtainable without root. See helpers/network.sh.
