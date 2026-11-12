#!/usr/bin/env bash
# Point Alacritty at the Catppuccin flavor matching the macOS appearance. It
# imports this file after the static lib/theme flavor and live-reloads it.

if [[ $(defaults read -g AppleInterfaceStyle 2>/dev/null) == "Dark" ]]; then
	flavor=mocha
else
	flavor=latte
fi

src="$HOME/.config/alacritty/themes/catppuccin-$flavor.toml"
dst="$HOME/.config/theme/alacritty-appearance.toml"
cmp -s "$src" "$dst" || cat "$src" >"$dst"
