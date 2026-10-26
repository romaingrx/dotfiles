#!/usr/bin/env bash

# Lights the Tailscale logo while its VPN is connected.

if scutil --nc list 2>/dev/null | grep -qi '(Connected).*tailscale'; then
	logo="$SKETCHYBAR_TAILSCALE_ON"
else
	logo="$SKETCHYBAR_TAILSCALE_OFF"
fi

sketchybar --set "$NAME" background.image="$logo"
