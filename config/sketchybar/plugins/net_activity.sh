#!/usr/bin/env bash

# Fast path for the net.activity graph.
#
# This item used to share plugins/wifi.sh, which cost 95.3 ms/invoke because it
# also gathered SSID, link rate, VPN name and IP for the popup — none of which
# the graph draws. The two expensive calls were `scutil --nc list` (24.0 ms) and
# `networksetup -listallhardwareports` (19.2 ms), both on a 2-second timer.
# The graph needs interface byte counters and nothing else.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/env.sh"
sketchybar_resolve_paths "$SCRIPT_DIR"

source "$CONFIG_DIR/colors.sh" || exit 1
source "$HELPER_DIR/network.sh"

iface="$(network_wifi_interface)" || exit 0

IFS="|" read -r down_graph up_graph down_label up_label dominant <<EOF
$(network_rates "$iface" || true)
EOF

down_graph="${down_graph:-0}"
up_graph="${up_graph:-0}"
down_label="${down_label:-0B/s}"
up_label="${up_label:-0B/s}"

if [ "${dominant:-down}" = "up" ]; then
	activity_graph="$up_graph"
	activity_label="↑${up_label%/s}"
	activity_color="$GREEN"
	activity_fill_color="$NET_UPLOAD_FILL"
else
	activity_graph="$down_graph"
	activity_label="↓${down_label%/s}"
	activity_color="$BLUE"
	activity_fill_color="$NET_DOWNLOAD_FILL"
fi

sketchybar --set net.activity \
	label="$activity_label" \
	label.color="$activity_color" \
	graph.color="$activity_color" \
	graph.fill_color="$activity_fill_color" \
	--push net.activity "$activity_graph"
