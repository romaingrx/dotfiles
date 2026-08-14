#!/usr/bin/env bash

# `pmset -g batt` costs 6.3 ms/call. The four accessors below used to invoke it
# once each (four forks, four IOKit power queries) for one snapshot of the same
# data. Cache it in the process instead.
_BATTERY_PMSET_CACHE=""

battery_pmset() {
	[ -n "$_BATTERY_PMSET_CACHE" ] || _BATTERY_PMSET_CACHE="$(pmset -g batt 2>/dev/null)"
	printf "%s\n" "$_BATTERY_PMSET_CACHE"
}

battery_percentage() {
	battery_pmset | grep -Eo "[0-9]+%" | head -n 1 | tr -d "%"
}

battery_source() {
	battery_pmset | awk -F "'" '/Now drawing from/ { print $2; exit }'
}

battery_status_line() {
	battery_pmset | awk '/InternalBattery/ { print; exit }'
}

battery_charging_state() {
	battery_status_line | awk -F "; *" '{ print $2 }'
}

battery_time_remaining() {
	battery_status_line | awk -F "; *" '{ print $3 }'
}

battery_health_details() {
	system_profiler SPPowerDataType 2>/dev/null |
		awk -F ": " '
      /Cycle Count/ { cycle = $2 }
      /Condition/ { condition = $2 }
      /Maximum Capacity/ { capacity = $2 }
      END {
        print (condition ? condition : "Unknown") "|" \
              (cycle ? cycle : "--") "|" \
              (capacity ? capacity : "--")
      }
    '
}
