#!/usr/bin/env bash

text_truncate() {
	local value="${1:-}"
	local max="${2:-40}"

	if [ "${#value}" -le "$max" ]; then
		printf "%s" "$value"
		return
	fi

	if [ "$max" -le 3 ]; then
		printf "%s" "${value:0:max}"
		return
	fi

	printf "%s..." "${value:0:max-3}"
}

text_human_layout() {
	case "${1:-}" in
	h_tiles) printf "horizontal" ;;
	v_tiles) printf "vertical" ;;
	h_accordion | v_accordion) printf "accordion" ;;
	floating) printf "floating" ;;
	"") printf "unknown" ;;
	*) printf "%s" "$1" ;;
	esac
}
