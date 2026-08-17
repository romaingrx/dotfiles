#!/usr/bin/env bash
# A/B: AirDrop DiscoverableMode = Everyone (current) vs Off.
# Hypothesis: AirDrop=Everyone keeps AWDL beaconing, driving airportd (~4.8% of a core).
# 3287 AWDL log lines in 5 minutes system-wide were measured before this run.
set -uo pipefail

SCRATCH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WINDOW="${1:-90}"
ORIG="$(defaults read com.apple.sharingd DiscoverableMode 2>/dev/null || echo "Everyone")"

restore() {
	echo
	echo "=== RESTORE ==="
	defaults write com.apple.sharingd DiscoverableMode -string "$ORIG"
	launchctl kickstart -k "gui/$UID/com.apple.sharingd" >/dev/null 2>&1
	sleep 2
	local now
	now="$(defaults read com.apple.sharingd DiscoverableMode 2>/dev/null)"
	if [ "$now" = "$ORIG" ]; then
		echo "  RESTORE OK — DiscoverableMode back to '$now', sharingd pid $(pgrep -x sharingd | tr '\n' ' ')"
	else
		echo "  !! RESTORE FAILED — expected '$ORIG', got '$now'"
	fi
}
trap restore EXIT INT TERM

awdl_rate() { # AWDL log lines in the last minute = independent activity proxy
	/usr/bin/log show --predicate 'eventMessage CONTAINS "awdl"' --last 1m --style compact 2>/dev/null | wc -l | tr -d ' '
}

echo "=== PRE-FLIGHT ==="
echo "  DiscoverableMode: $ORIG"
echo "  sharingd pid: $(pgrep -x sharingd | tr '\n' ' ')"

echo
echo "=== CONTROL: AirDrop = $ORIG (${WINDOW}s) ==="
python3 "$SCRATCH/cpudelta.py" "$WINDOW" "CONTROL AirDrop=$ORIG"
echo "  AWDL log lines in last 1m: $(awdl_rate)"

echo
echo "=== TREATMENT SETUP: AirDrop = Off ==="
defaults write com.apple.sharingd DiscoverableMode -string "Off"
launchctl kickstart -k "gui/$UID/com.apple.sharingd" >/dev/null 2>&1
sleep 5
echo "  VERIFIED DiscoverableMode now: $(defaults read com.apple.sharingd DiscoverableMode 2>/dev/null)"

echo
echo "=== TREATMENT: AirDrop = Off (${WINDOW}s) ==="
python3 "$SCRATCH/cpudelta.py" "$WINDOW" "TREATMENT AirDrop=Off"
echo "  AWDL log lines in last 1m: $(awdl_rate)"
