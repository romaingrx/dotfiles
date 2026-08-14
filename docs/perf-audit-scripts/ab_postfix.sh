#!/usr/bin/env bash
# A/B: current live sketchybar config vs the fixed config in the worktree.
#
# The worktree is swapped in by repointing the ~/.config/sketchybar symlink, so
# ~/.dotfiles is never touched. The original symlink target is captured first and
# restored by the trap.
set -uo pipefail

SCRATCH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKTREE_CFG="/Users/romaingrx/.dotfiles/.claude/worktrees/perf-audit/config/sketchybar"
LINK="$HOME/.config/sketchybar"
LABEL="org.nixos.sketchybar"
WINDOW="${1:-90}"

ORIG_TARGET="$(readlink "$LINK")"
[ -n "$ORIG_TARGET" ] || {
	echo "!! $LINK is not a symlink — aborting, this script would clobber a real directory"
	exit 1
}

reload() {
	launchctl kickstart -k "gui/$UID/$LABEL" >/dev/null 2>&1
	sleep 8
}

restore() {
	echo
	echo "=== RESTORE ==="
	ln -sfn "$ORIG_TARGET" "$LINK"
	reload
	local now items
	now="$(readlink "$LINK")"
	items="$(sketchybar --query bar 2>/dev/null | python3 -c "import json,sys; print(len(json.load(sys.stdin).get('items',[])))" 2>/dev/null || echo 0)"
	if [ "$now" = "$ORIG_TARGET" ] && [ "$items" -gt 10 ]; then
		echo "  RESTORE OK — symlink back to original, $items items in bar, pid $(pgrep -x sketchybar | tr '\n' ' ')"
	else
		echo "  !! RESTORE PROBLEM — symlink='$now' items=$items"
		echo "  !! fix with: ln -sfn '$ORIG_TARGET' '$LINK' && launchctl kickstart -k gui/$UID/$LABEL"
	fi
	# the fixed config removes wifi.speed; its presence confirms the original is back
	if sketchybar --query bar 2>/dev/null | grep -q "wifi.speed"; then
		echo "  CONFIRMED: original config active (wifi.speed item present)"
	else
		echo "  !! original config may NOT be active (wifi.speed missing)"
	fi
}
trap restore EXIT INT TERM

echo "=== PRE-FLIGHT ==="
echo "  original symlink target: $ORIG_TARGET"
echo "  worktree config:         $WORKTREE_CFG"

echo
echo "=== CONTROL: current config (${WINDOW}s) ==="
reload
python3 "$SCRATCH/cpudelta.py" "$WINDOW" "CONTROL current sketchybar config"

echo
echo "=== TREATMENT SETUP: point ~/.config/sketchybar at the worktree ==="
ln -sfn "$WORKTREE_CFG" "$LINK"
reload
echo "  symlink now: $(readlink "$LINK")"
if sketchybar --query bar 2>/dev/null | grep -q "wifi.speed"; then
	echo "  !! wifi.speed still present — fixed config did NOT load. Aborting."
	exit 1
fi
echo "  VERIFIED: fixed config loaded (wifi.speed item is gone, as intended)"
echo "  items in bar: $(sketchybar --query bar 2>/dev/null | python3 -c "import json,sys; print(len(json.load(sys.stdin).get('items',[])))")"

echo
echo "=== TREATMENT: fixed config (${WINDOW}s) ==="
python3 "$SCRATCH/cpudelta.py" "$WINDOW" "TREATMENT fixed sketchybar config"

echo
echo "=== TREATMENT-2: fixed config, second window (${WINDOW}s) ==="
python3 "$SCRATCH/cpudelta.py" "$WINDOW" "TREATMENT-2 fixed sketchybar config"
