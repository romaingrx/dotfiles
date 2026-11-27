#!/usr/bin/env bash
# A thread's report to its orchestrator. The report is a file, and the thread's
# terminal carries its state and the file's path as labels, so the report is
# not lost when the orchestrator is away. The message only wakes the
# orchestrator.
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: report.sh <done|review|needs-you> <report-file> [--pr <url>]... [--drop-pr <url>]...
  done       the work the person asked for has ended.
  review     the work waits for the person's review, such as a pull request. The thread can go on after it.
  needs-you  the thread cannot continue without the person, or without an answer from the orchestrator.
  --pr <url>       a pull request this thread owns. Name it once: it stays declared in later reports.
  --drop-pr <url>  one that is no longer this thread's: closed without a merge, or replaced.
Run it in the thread's own terminal.
EOF
  exit 2
}

# A pull request's URL as `gh pr create` prints it; what follows the number (/files, a query) is cut off.
# The mod reads the label with the same form and the same limit (src/pulls.ts).
pull_url='^(https://[^/[:space:]]+/[^/[:space:]]+/[^/[:space:]]+/pull/[0-9]+)([/?#].*)?$'
max_pulls=8

fail() {
  echo "report: $1" >&2
  exit 1
}

[[ $# -ge 2 ]] || usage
state=$1
report=$2
shift 2
[[ $state == "done" || $state == "review" || $state == "needs-you" ]] || usage

# Only the form of a URL is checked: a report must not fail because GitHub is away.
add='' drop=''
while [[ $# -gt 0 ]]; do
  [[ $1 == "--pr" || $1 == "--drop-pr" ]] || usage
  [[ $# -ge 2 && $2 =~ $pull_url ]] || fail "$1 takes the URL of a pull request, as gh pr create prints it"
  case $1 in
    --pr) add+=" ${BASH_REMATCH[1]}" ;;
    --drop-pr) drop+=" ${BASH_REMATCH[1]}" ;;
  esac
  shift 2
done
[[ -s $report ]] || fail "the report is missing or empty: $report"
[[ -n ${HC_TERMINAL_ID:-} ]] || fail "this is not a Herdr terminal"

report=$(cd -- "$(dirname -- "$report")" && pwd)/$(basename -- "$report")
me=$(hc get "$HC_TERMINAL_ID" --json)
project=$(jq -r '.labels.project // empty' <<<"$me")
title=$(jq -r '.labels.title // .name' <<<"$me")
[[ -n $project ]] || fail "this terminal is not a thread of a project"

# The pull requests this thread owns are a set: what it declared before, with those of this
# report added and dropped. Sorted, so the same report twice gives the same label.
pulls=$(jq -r --arg add "$add" --arg drop "$drop" '
  def urls: split(" ") | map(select(. != ""));
  ((.labels.pulls // "") | urls) + ($add | urls) - ($drop | urls) | unique | join(" ")' <<<"$me")
(($(wc -w <<<"$pulls") <= max_pulls)) || fail "a thread declares $max_pulls pull requests at most"

turn=$(jq -r '.turn' <<<"$me")
# `report-turn` lets the sidebar tell a report about this turn from an old one. A new report
# reopens a resolved thread and clears `handled`, the orchestrator's mark on a report it dealt with.
# An empty value removes a label.
hc label "$HC_TERMINAL_ID" "state=$state" "report=$report" "report-turn=$turn" "pulls=$pulls" handled= resolved= >/dev/null

# A thread and its orchestrator run on one machine: an address without a machine is on this one.
orchestrator=$(hc ls --json --label "project=$project" --label role=orchestrator |
  jq -r '[.terminals[] | select(.agent == "claude-code" and (.address | contains("/") | not))][0].address // empty')
if [[ -z $orchestrator ]]; then
  echo "saved. No orchestrator of $project is running: it reads the report when it starts."
  exit 0
fi
hc send "$orchestrator" "The thread \"$title\" ($HC_TERMINAL_ID) reports: $state. Run threads.sh and read its report." >/dev/null
echo "saved, and the orchestrator ($orchestrator) is told."
