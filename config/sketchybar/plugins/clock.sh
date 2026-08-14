#!/usr/bin/env sh

# No %S: seconds forced update_freq=1, i.e. 60 forks/min for a digit that is
# unreadable at a glance anyway. At update_freq=15 the minute is at most 15s
# stale. See docs/perf-audit-2026-08.md for the cost table.
sketchybar --set "$NAME" label="$(date '+%h %d - %H:%M')"
