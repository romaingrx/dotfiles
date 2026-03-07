#!/usr/bin/env bash
# Watches macOS appearance (light/dark) and updates the active alacritty theme.
# Alacritty auto-reloads when the imported file changes.

set -euo pipefail

THEMES_DIR="${HOME}/.config/alacritty/themes"
ACTIVE_THEME="${HOME}/.local/share/alacritty/active-theme.toml"

mkdir -p "$(dirname "$ACTIVE_THEME")"

get_appearance() {
  if defaults read -g AppleInterfaceStyle &>/dev/null; then
    echo "dark"
  else
    echo "light"
  fi
}

apply_theme() {
  local appearance="$1"
  local theme_file
  if [[ "$appearance" == "dark" ]]; then
    theme_file="${THEMES_DIR}/catppuccin-mocha.toml"
  else
    theme_file="${THEMES_DIR}/catppuccin-latte.toml"
  fi

  ln -sf "$theme_file" "$ACTIVE_THEME"
}

# Apply immediately on start
current=$(get_appearance)
apply_theme "$current"

# Poll for changes every 2 seconds
while true; do
  sleep 2
  new=$(get_appearance)
  if [[ "$new" != "$current" ]]; then
    current="$new"
    apply_theme "$current"
  fi
done
