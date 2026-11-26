#!/usr/bin/env bash
# The threads of a project, with what each one last reported. The orchestrator
# reads this when it starts and each time it wakes: the labels and the report
# files hold the state, not its context.
set -euo pipefail

[[ $# -eq 1 ]] || {
  echo "usage: threads.sh <project>" >&2
  exit 2
}
project=$1

hc ls --json --label "project=$project" --label role=thread |
  jq -r '.terminals[].address' |
  while read -r address; do
    hc get "$address" --json | jq -r '
      [ .address,
        (.labels.title // .name),
        "now: " + (.status.state // "not an agent"),
        "reported: " + (.labels.state // "nothing"),
        (if .labels.report then "report: " + .labels.report else "no report" end),
        (if .labels.handled == "true" then "handled" else "not handled" end),
        (if .labels.resolved == "true" then "resolved" else "open" end)
      ] | join(" | ")'
  done
