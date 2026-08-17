#!/usr/bin/env bash

# One process-table walk instead of two, and no `whoami` forks.
#
# The previous version cost 91 ms/invoke at update_freq=2. It ran
# `ps -eo pcpu,user` (21.8 ms) AND `ps axo %cpu,ucomm` (17.5 ms) — two full walks
# of ~600 processes — plus `whoami` twice (2.2 ms each) and six grep/sed/awk
# forks. Resolving a username for every row is what drove opendirectoryd; the A/B
# showed opendirectoryd falling 3.16% -> 2.17% when sketchybar was stopped.
#
# CAVEAT, unchanged from the original: `ps -o pcpu` is a process-LIFETIME average,
# not current load, so this number has always been closer to "average CPU since
# boot" than "CPU now". Making it correct needs a sampling source; the compiled
# event provider `sketchybar-system-stats` is the real fix. See
# docs/perf-audit-2026-08.md.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/env.sh"
sketchybar_resolve_paths "$SCRIPT_DIR"

source "$CONFIG_DIR/colors.sh" || exit 1

CORE_COUNT=$(sysctl -n machdep.cpu.thread_count)

IFS="|" read -r CPU_SYS CPU_USER CPU_TOTAL TOPPROC <<EOF
$(ps -Axo pcpu,user,ucomm | awk -v me="${USER:-$LOGNAME}" -v cores="$CORE_COUNT" '
  NR > 1 {
    if ($2 == me) user += $1; else sys += $1
    if ($1 > topv) { topv = $1; topc = $3 }
  }
  END {
    gsub(/com\.apple\./, "", topc)
    printf "%.4f|%.4f|%.0f|%.0f%% %s",
      sys / (100.0 * cores), user / (100.0 * cores),
      (sys + user) / cores, topv, topc
  }
')
EOF

COLOR=$WHITE
case "$CPU_TOTAL" in
[8-9][0-9] | 100) COLOR=$RED ;;
[6-7][0-9]) COLOR=$ORANGE ;;
[4-5][0-9]) COLOR=$YELLOW ;;
esac

sketchybar --set cpu.user \
	label="$CPU_TOTAL%" \
	label.color="$COLOR" \
	graph.color="$COLOR" \
	--set cpu.top label="$TOPPROC" \
	--push cpu.sys "$CPU_SYS" \
	--push cpu.user "$(awk -v s="$CPU_SYS" -v u="$CPU_USER" 'BEGIN { print s + u }')"
