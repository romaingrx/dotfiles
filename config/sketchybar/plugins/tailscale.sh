#!/usr/bin/env bash

# Lights the Tailscale logo while its VPN is connected.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/env.sh"
sketchybar_resolve_paths "$SCRIPT_DIR"
source "$CONFIG_DIR/colors.sh" || exit 1

if scutil --nc list 2>/dev/null | grep -qi '(Connected).*tailscale'; then
	color="$THEME_FG"
else
	color="$THEME_MUTED"
fi

sketchybar --set "$NAME" icon.color="$color"
