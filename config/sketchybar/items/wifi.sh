#!/usr/bin/env bash

sketchybar --add item wifi.control right \
	--set wifi.control \
	icon="$WIFI_ICN" \
	label.drawing=off \
	script="$PLUGIN_DIR/wifi.sh" \
	update_freq=30 \
	click_script="$PLUGIN_DIR/wifi_click.sh" \
	popup.background.color=0x70000000 \
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

sketchybar --add item wifi.speed popup.wifi.control \
	--set wifi.speed \
	icon="$SPEED_ICN" \
	label="-- Mbps" \
	background.padding_left=6 \
	background.padding_right=8
