#!/usr/bin/env bash
# A thread's report to its orchestrator. The report is a file, and the thread's
# terminal carries its state and the file's path as labels, so the report is
# not lost when the orchestrator is away. The message only wakes the
# orchestrator.
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: report.sh <done|review|needs-you> <report-file>
  done       the work the person asked for has ended.
  review     the work waits for the person's review, such as a pull request. The thread can go on after it.
  needs-you  the thread cannot continue without the person, or without an answer from the orchestrator.
Run it in the thread's own terminal.
EOF
  exit 2
}

fail() {
  echo "report: $1" >&2
  exit 1
}

[[ $# -eq 2 ]] || usage
state=$1
report=$2
[[ $state == "done" || $state == "review" || $state == "needs-you" ]] || usage
[[ -s $report ]] || fail "the report is missing or empty: $report"
[[ -n ${HC_TERMINAL_ID:-} ]] || fail "this is not a Herdr terminal"

report=$(cd -- "$(dirname -- "$report")" && pwd)/$(basename -- "$report")
me=$(hc get "$HC_TERMINAL_ID" --json)
project=$(jq -r '.labels.project // empty' <<<"$me")
title=$(jq -r '.labels.title // .name' <<<"$me")
[[ -n $project ]] || fail "this terminal is not a thread of a project"

turn=$(jq -r '.turn' <<<"$me")
# `report-turn` lets the sidebar tell a report about this turn from an old one. A new report
# reopens a resolved thread and clears `handled`, the orchestrator's mark on a report it dealt with.
hc label "$HC_TERMINAL_ID" "state=$state" "report=$report" "report-turn=$turn" handled= resolved= >/dev/null

# A thread and its orchestrator run on one machine: an address without a machine is on this one.
orchestrator=$(hc ls --json --label "project=$project" --label role=orchestrator |
  jq -r '[.terminals[] | select(.agent == "claude-code" and (.address | contains("/") | not))][0].address // empty')
if [[ -z $orchestrator ]]; then
  echo "saved. No orchestrator of $project is running: it reads the report when it starts."
  exit 0
fi
hc send "$orchestrator" "The thread \"$title\" ($HC_TERMINAL_ID) reports: $state. Run threads.sh and read its report." >/dev/null
echo "saved, and the orchestrator ($orchestrator) is told."
