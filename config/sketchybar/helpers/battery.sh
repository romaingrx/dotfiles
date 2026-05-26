#!/usr/bin/env bash

battery_pmset() {
	pmset -g batt 2>/dev/null
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
