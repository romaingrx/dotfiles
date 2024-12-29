#!/bin/sh

# Get memory info using vm_stat
PAGE_SIZE=$(pagesize)
VM_STAT=$(vm_stat)

PAGES_FREE=$(echo "$VM_STAT" | grep "Pages free:" | awk '{print $3}' | sed 's/\.//')
PAGES_ACTIVE=$(echo "$VM_STAT" | grep "Pages active:" | awk '{print $3}' | sed 's/\.//')
PAGES_INACTIVE=$(echo "$VM_STAT" | grep "Pages inactive:" | awk '{print $3}' | sed 's/\.//')
PAGES_SPECULATIVE=$(echo "$VM_STAT" | grep "Pages speculative:" | awk '{print $3}' | sed 's/\.//')
PAGES_WIRED=$(echo "$VM_STAT" | grep "Pages wired down:" | awk '{print $4}' | sed 's/\.//')

# Calculate used memory
USED_MEM=$((((PAGES_ACTIVE + PAGES_INACTIVE + PAGES_SPECULATIVE + PAGES_WIRED) * PAGE_SIZE) / 1024 / 1024))

# Get total memory
TOTAL_MEM=$(sysctl -n hw.memsize)
TOTAL_MEM=$((TOTAL_MEM / 1024 / 1024))

# Calculate percentage
MEMORY_PERCENT=$(echo "scale=2; ($USED_MEM * 100) / $TOTAL_MEM" | bc)
ROUNDED_PERCENT=$(printf "%.0f" "$MEMORY_PERCENT")

# Format label
if [ "$ROUNDED_PERCENT" -lt 10 ]; then
  LABEL=" ${ROUNDED_PERCENT}%"
else
  LABEL="${ROUNDED_PERCENT}%"
fi

sketchybar --set memory label="$LABEL" 