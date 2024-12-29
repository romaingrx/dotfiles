#!/bin/sh

# Cache file for storing previous values
CACHE_FILE="/tmp/network_cache"

# Get current bytes in/out
NETWORK_STATS=$(netstat -bI en0 | grep -e "en0")
BYTES_IN=$(echo "$NETWORK_STATS" | awk '{print $7}')
BYTES_OUT=$(echo "$NETWORK_STATS" | awk '{print $10}')

# Read previous values from cache
if [ -f "$CACHE_FILE" ]; then
    read -r PREV_IN PREV_OUT PREV_TIME < "$CACHE_FILE"
else
    PREV_IN=0
    PREV_OUT=0
    PREV_TIME=0
fi

# Get current timestamp
CURRENT_TIME=$(date +%s)

# Calculate time difference
TIME_DIFF=$((CURRENT_TIME - PREV_TIME))
if [ "$TIME_DIFF" -eq 0 ]; then
    TIME_DIFF=1
fi

# Calculate speed
BYTES_IN_DIFF=$((BYTES_IN - PREV_IN))
BYTES_OUT_DIFF=$((BYTES_OUT - PREV_OUT))
SPEED_IN=$((BYTES_IN_DIFF / TIME_DIFF))
SPEED_OUT=$((BYTES_OUT_DIFF / TIME_DIFF))

# Convert to appropriate unit and round
format_speed() {
    SPEED=$1
    if [ "$SPEED" -gt 1048576 ]; then
        echo "$(echo "scale=1; $SPEED/1048576" | bc)MB/s"
    elif [ "$SPEED" -gt 1024 ]; then
        echo "$(echo "scale=1; $SPEED/1024" | bc)KB/s"
    else
        echo "${SPEED}B/s"
    fi
}

SPEED_IN_FORMATTED=$(format_speed "$SPEED_IN")
SPEED_OUT_FORMATTED=$(format_speed "$SPEED_OUT")

# Save current values to cache
echo "$BYTES_IN $BYTES_OUT $CURRENT_TIME" > "$CACHE_FILE"

# Update label with speeds
LABEL="↓${SPEED_IN_FORMATTED} ↑${SPEED_OUT_FORMATTED}"
sketchybar --set network label="$LABEL" 