#!/bin/sh

# Cache file for storing previous values (used for smoothing)
CACHE_FILE="/tmp/cpu_cache"

# Get CPU usage percentage using top command
CPU_INFO=$(top -l 2 -n 0 -s 0 | grep "CPU usage" | tail -1 | awk '{print $3}' | cut -d'.' -f1)

# Ensure we have a valid number
if [ -z "$CPU_INFO" ] || [ "$CPU_INFO" -lt 0 ]; then
  CPU_INFO=0
elif [ "$CPU_INFO" -gt 100 ]; then
  CPU_INFO=100
fi

# Read previous value from cache (if exists)
if [ -f "$CACHE_FILE" ]; then
  PREV_VALUE=$(cat "$CACHE_FILE")
else
  PREV_VALUE=$CPU_INFO
fi

# Simple exponential smoothing
ALPHA=0.3  # Smoothing factor (0 < α < 1)
SMOOTHED_VALUE=$(echo "scale=2; ($ALPHA * $CPU_INFO) + ((1 - $ALPHA) * $PREV_VALUE)" | bc)
ROUNDED_VALUE=$(printf "%.0f" "$SMOOTHED_VALUE")

# Save current smoothed value to cache
echo "$SMOOTHED_VALUE" > "$CACHE_FILE"

# Update the label (showing actual percentage)
if [ "$ROUNDED_VALUE" -lt 10 ]; then
  LABEL=" ${ROUNDED_VALUE}%"
else
  LABEL="${ROUNDED_VALUE}%"
fi

sketchybar --set cpu label="$LABEL" 