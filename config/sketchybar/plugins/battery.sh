#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${CONFIG_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
HELPER_DIR="${HELPER_DIR:-$CONFIG_DIR/helpers}"

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"
source "$HELPER_DIR/battery.sh"

percentage="$(battery_percentage)"
source_name="$(battery_source)"
state="$(battery_charging_state)"
time_remaining="$(battery_time_remaining)"

[ -n "$percentage" ] || exit 0

case "$percentage" in
9[0-9] | 100) icon="$BATTERY_100" ;;
[6-8][0-9]) icon="$BATTERY_75" ;;
[3-5][0-9]) icon="$BATTERY_50" ;;
[1-2][0-9]) icon="$BATTERY_25" ;;
*) icon="$BATTERY_10" ;;
esac

label_color="$WHITE"
icon_color="$WHITE"
case "$percentage" in
[1-9] | 1[0-9]) label_color="$RED" ;;
2[0-9]) label_color="$YELLOW" ;;
esac

if [ "$source_name" = "AC Power" ]; then
	icon="$BATTERY_CHARGING"
	icon_color="$GREEN"
fi

sketchybar --set battery \
	icon="$icon" \
	icon.color="$icon_color" \
	label="${percentage}%" \
	label.color="$label_color" \
	--set battery.source \
	icon="$POWER_ICN" \
	label="${source_name:-Unknown} - ${state:-unknown}" \
	--set battery.time \
	icon="$CLOCK_ICN" \
	label="${time_remaining:-No estimate}"

if [ "${1:-}" = "--details" ]; then
	IFS="|" read -r condition cycles capacity <<EOF
$(battery_health_details)
EOF

	sketchybar --set battery.health \
		icon="$HEALTH_ICN" \
		label="Condition: $condition - Capacity: $capacity" \
		--set battery.cycles \
		icon="$BATTERY_100" \
		label="Cycle count: $cycles"
fi
