#!/usr/bin/env sh

theme_config="${ROMAINGRX_THEME_CONFIG:-${HOME}/.config/romaingrx/theme/paths.env}"
if [ -r "$theme_config" ]; then
	# shellcheck source=/dev/null
	. "$theme_config"
fi

theme_state_root="${ROMAINGRX_THEME_RUNTIME_ROOT:-${XDG_STATE_HOME:-${HOME}/.local/state}/theme}"
theme_colors="${theme_state_root}/current/sketchybar/colors.sh"

if [ ! -r "$theme_colors" ]; then
	printf 'Missing SketchyBar theme colors: %s\n' "$theme_colors" >&2
	return 1 2>/dev/null || exit 1
fi

# shellcheck source=/dev/null
. "$theme_colors"
