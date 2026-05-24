#!/usr/bin/env bash

sketchybar --add graph net.activity right 42 \
	--set net.activity \
	graph.color="$BLUE" \
	graph.fill_color=0x208aadf4 \
	graph.line_width=0.8 \
	label="0B" \
	label.drawing=on \
	label.font="$FONT:Medium:9.0" \
	label.color="$BLUE" \
	label.padding_left=2 \
	label.padding_right=3 \
	icon.drawing=off \
	background.drawing=on \
	background.color="$STATUS_GRAPH_BG" \
	background.corner_radius="$STATUS_RADIUS" \
	background.height=18 \
	background.padding_left=3 \
	background.padding_right=4 \
	script="$PLUGIN_DIR/wifi.sh" \
	update_freq=2 \
	--subscribe net.activity system_woke wifi_change

sketchybar --add item wifi.control right \
	--set wifi.control \
	icon="$WIFI_ICN" \
	icon.padding_left=6 \
	icon.padding_right=3 \
	label.font="$APP_FONT:Regular:12.0" \
	label.padding_left=1 \
	label.padding_right=6 \
	label.drawing=off \
	script="$PLUGIN_DIR/wifi.sh" \
	update_freq=30 \
	click_script="$PLUGIN_DIR/wifi_click.sh" \
	background.drawing=on \
	background.color="$STATUS_BG" \
	background.corner_radius="$STATUS_RADIUS" \
	background.height="$STATUS_HEIGHT" \
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
