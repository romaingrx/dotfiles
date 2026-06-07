#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/env.sh"
sketchybar_resolve_paths "$SCRIPT_DIR"

source "$CONFIG_DIR/colors.sh" || exit 1

CORE_COUNT=$(sysctl -n machdep.cpu.thread_count)
CPU_INFO=$(ps -eo pcpu,user)
CPU_SYS=$(echo "$CPU_INFO" | grep -v $(whoami) | sed "s/[^ 0-9\.]//g" | awk "{sum+=\$1} END {print sum/(100.0 * $CORE_COUNT)}")
CPU_USER=$(echo "$CPU_INFO" | grep $(whoami) | sed "s/[^ 0-9\.]//g" | awk "{sum+=\$1} END {print sum/(100.0 * $CORE_COUNT)}")

TOPPROC=$(ps axo "%cpu,ucomm" | sort -nr | tail +1 | head -n1 | awk '{printf "%.0f%% %s\n", $1, $2}' | sed -e 's/com.apple.//g')
CPUP=$(echo $TOPPROC | sed -nr 's/([^\%]+).*/\1/p')

CPU_PERCENT="$(echo "$CPU_SYS $CPU_USER" | awk '{printf "%.0f\n", ($1 + $2)*100}')"

COLOR=$WHITE
case "$CPU_PERCENT" in
[8-9][0-9] | 100)
	COLOR=$RED
	;;
[6-7][0-9]) COLOR=$ORANGE ;;
[4-5][0-9]) COLOR=$YELLOW ;;
esac

sketchybar --set cpu.user \
	label="$CPU_PERCENT%" \
	label.color=$COLOR \
	graph.color=$COLOR \
	--set cpu.top label="$TOPPROC" \
	--push cpu.sys $CPU_SYS \
	--push cpu.user "$(echo "$CPU_SYS $CPU_USER" | awk '{print $1 + $2}')"
