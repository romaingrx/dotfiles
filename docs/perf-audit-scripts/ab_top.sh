#!/usr/bin/env bash
# REJECTED INSTRUMENT — kept because the rejection is part of the result.
#
# Whole-system A/B of the two sketchybar configs using `top`'s kernel counters.
# The idea was to confirm the os.times()-derived saving against a measurement
# that sees short-lived forks (ps-delta sampling does not).
#
# It did not resolve. Three alternating pairs gave -13.28, -10.40, +9.44 — the
# third flipped sign, leaving mean -4.75, sd 12.37, paired t = -0.66. Background
# load on this machine drifts by ~30% of one core between windows, which is
# twice the effect being measured, so no realistic number of pairs would have
# rescued it. Direct fork counting (forkcount.py) answered the same question at
# roughly 100x the resolution.
#
# Read this alongside paired.py, which does the paired-difference analysis, and
# docs/perf-audit-2026-08.md section 4 for why the null here is an instrument
# limit rather than evidence against the saving.
set -uo pipefail

SCRATCH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKTREE_CFG="/Users/romaingrx/.dotfiles/.claude/worktrees/perf-audit/config/sketchybar"
LINK="$HOME/.config/sketchybar"
LABEL="org.nixos.sketchybar"
W="${1:-45}"
PAIRS="${2:-3}"

ORIG_TARGET="$(readlink "$LINK")"
[ -n "$ORIG_TARGET" ] || {
	echo "!! $LINK not a symlink, aborting"
	exit 1
}

restore() {
	echo
	echo "=== RESTORE ==="
	ln -sfn "$ORIG_TARGET" "$LINK"
	launchctl kickstart -k "gui/$UID/$LABEL" >/dev/null 2>&1
	sleep 6
	if [ "$(readlink "$LINK")" = "$ORIG_TARGET" ] && sketchybar --query bar 2>/dev/null | grep -q wifi.speed; then
		echo "  RESTORE OK — original config active (wifi.speed present), pid $(pgrep -x sketchybar)"
	else
		echo "  !! RESTORE PROBLEM — run: ln -sfn '$ORIG_TARGET' '$LINK' && launchctl kickstart -k gui/$UID/$LABEL"
	fi
}
trap restore EXIT INT TERM

busy() { # % of ONE core, SECOND top sample only — the first is a lifetime average
	top -l 2 -n 0 -s "$W" 2>/dev/null |
		awk '/CPU usage/ { u=$3; s=$5; sub(/%/,"",u); sub(/%/,"",s); last=(u+s)*16 } END { printf "%.2f", last }'
}

use_cfg() { # $1 = orig|fixed ; verifies the swap actually took effect
	if [ "$1" = fixed ]; then ln -sfn "$WORKTREE_CFG" "$LINK"; else ln -sfn "$ORIG_TARGET" "$LINK"; fi
	launchctl kickstart -k "gui/$UID/$LABEL" >/dev/null 2>&1
	sleep 8
	local has
	sketchybar --query bar 2>/dev/null | grep -q wifi.speed && has=orig || has=fixed
	if [ "$has" != "$1" ]; then
		echo "  !! wanted $1 config but bar reports $has — aborting"
		exit 1
	fi
}

echo "=== ${PAIRS} alternating pairs, ${W}s per window, real sketchybar, top kernel counters ==="
echo
o_sum=0
f_sum=0
for i in $(seq 1 "$PAIRS"); do
	use_cfg orig
	o=$(busy)
	echo "  pair $i  ORIGINAL config : ${o}% of one core"
	use_cfg fixed
	f=$(busy)
	echo "  pair $i  FIXED    config : ${f}% of one core   (delta $(awk -v a="$o" -v b="$f" 'BEGIN{printf "%+.2f", b-a}'))"
	o_sum=$(awk -v a="$o_sum" -v b="$o" 'BEGIN{print a+b}')
	f_sum=$(awk -v a="$f_sum" -v b="$f" 'BEGIN{print a+b}')
done

echo
awk -v o="$o_sum" -v f="$f_sum" -v n="$PAIRS" 'BEGIN {
	om=o/n; fm=f/n
	printf "  mean ORIGINAL : %7.2f%% of one core\n", om
	printf "  mean FIXED    : %7.2f%% of one core\n", fm
	printf "  MEASURED SAVING: %6.2f%% of one core   (os.times()+ps A/B predicted ~16.3)\n", om-fm
}'
