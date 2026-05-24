#!/usr/bin/env bash

sketchybar --add graph net.down right 44 \
	--set net.down \
	width=0 \
	graph.color="$BLUE" \
	graph.fill_color=0x308aadf4 \
	label.drawing=off \
	icon.drawing=off \
	background.padding_right=2

sketchybar --add graph net.up right 44 \
	--set net.up \
	graph.color="$GREEN" \
	graph.fill_color=0x30a6da95 \
	label.drawing=off \
	icon.drawing=off \
	background.padding_right=4 \
	script="$PLUGIN_DIR/wifi.sh" \
	update_freq=2 \
	--subscribe net.up system_woke wifi_change

sketchybar --add item wifi.control right \
	--set wifi.control \
	icon="$WIFI_ICN" \
	icon.padding_left=5 \
	icon.padding_right=3 \
	label.font="$NERD_FONT:Regular:11.0" \
	label.padding_left=0 \
	label.padding_right=5 \
	label.drawing=off \
	script="$PLUGIN_DIR/wifi.sh" \
	update_freq=30 \
	click_script="$PLUGIN_DIR/wifi_click.sh" \
	background.drawing=on \
	background.color=0x22000000 \
	background.corner_radius=6 \
	background.height=22 \
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
