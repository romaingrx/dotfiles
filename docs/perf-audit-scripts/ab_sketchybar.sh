#!/usr/bin/env bash
# A/B: sketchybar running vs really stopped.
# Per brief section 4 rule 3: a plain `kill` is invalid (KeepAlive respawns in <1s).
# Use launchctl bootout, VERIFY with pgrep, restore with bootstrap, all under a trap.
set -uo pipefail

LABEL="org.nixos.sketchybar"
PLIST="$HOME/Library/LaunchAgents/org.nixos.sketchybar.plist"
SCRATCH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WINDOW="${1:-90}"

restore() {
	echo
	echo "=== RESTORE ==="
	if ! pgrep -x sketchybar >/dev/null 2>&1; then
		launchctl bootstrap "gui/$UID" "$PLIST" 2>&1 | sed 's/^/  bootstrap: /'
		sleep 3
	fi
	if pgrep -x sketchybar >/dev/null 2>&1; then
		echo "  RESTORE OK — sketchybar pid: $(pgrep -x sketchybar | tr '\n' ' ')"
	else
		echo "  !! RESTORE FAILED — run: launchctl bootstrap gui/$UID $PLIST"
	fi
}
trap restore EXIT INT TERM

echo "=== PRE-FLIGHT ==="
echo "  sketchybar pid: $(pgrep -x sketchybar | tr '\n' ' ')"
echo "  aerospace pid:  $(pgrep -x AeroSpace | tr '\n' ' ')"
[ -r "$PLIST" ] || {
	echo "  !! plist not readable, aborting"
	exit 1
}

echo
echo "=== CONTROL: sketchybar RUNNING (${WINDOW}s) ==="
python3 "$SCRATCH/cpudelta.py" "$WINDOW" "CONTROL sketchybar running"

echo
echo "=== TREATMENT SETUP: bootout $LABEL ==="
launchctl bootout "gui/$UID/$LABEL" 2>&1 | sed 's/^/  bootout: /'
sleep 3
if pgrep -x sketchybar >/dev/null 2>&1; then
	echo "  !! sketchybar STILL RUNNING after bootout — measurement would be invalid. Aborting."
	exit 1
fi
echo "  VERIFIED: sketchybar is gone (pgrep empty)"
echo "  leftover forked children (bash/ps/awk under old parent): $(pgrep -P 1 -f 'sketchybar' | wc -l | tr -d ' ')"

echo
echo "=== TREATMENT: sketchybar STOPPED (${WINDOW}s) ==="
python3 "$SCRATCH/cpudelta.py" "$WINDOW" "TREATMENT sketchybar stopped"

echo
echo "=== TREATMENT-2: still stopped, second window for stability (${WINDOW}s) ==="
python3 "$SCRATCH/cpudelta.py" "$WINDOW" "TREATMENT-2 sketchybar stopped"
