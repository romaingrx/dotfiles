#!/usr/bin/env bash
# Start a session of a project in a Herdr terminal: its orchestrator, or a
# thread for one task. A project lives on one machine. The session gets the
# instructions of its role as an appended system prompt, and the labels that
# the sidebar groups by.
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: start.sh orchestrator <project> [--cwd <dir>] [--on <machine>] [--auto]
       start.sh thread <project> <task> <task-file> [--title <text>] [--cwd <dir>] [--auto]
  <project>       lowercase letters, digits and hyphens, 16 characters at most.
  <task>          the same characters. <project>-<task> takes 32 characters at most.
  --cwd <dir>     where the session starts (default: this folder). A thread in a git repository gets its own worktree.
  --on <machine>  start the orchestrator on another machine this core knows (hc machine ls). <dir> is then a path there.
  --title <text>  a thread's name in the thread list (default: its task name).
  --auto          start it with --permission-mode auto. Only when the user asked for an unattended session.

An orchestrator whose Claude ended is started again in place. Its threads start
on its own machine: run `start.sh thread` there.
EOF
  exit 2
}

fail() {
  echo "start: $1" >&2
  exit 1
}

kit=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# Where each machine keeps its copy of this folder, under its home. A session
# finds the scripts and its role there, whatever machine started it.
installed=.local/share/herdr-projects
# What one heavy command may take on a shared machine: do not start a session with less left.
min_free_gib=8
# How long Claude may take to come up in a new terminal.
starting_seconds=60
slug='^[a-z0-9][a-z0-9-]*$'

role=${1:-}
project=${2:-}
task=
task_file=
case $role in
  orchestrator)
    [[ $# -ge 2 ]] || usage
    shift 2
    ;;
  thread)
    [[ $# -ge 4 ]] || usage
    task=$3
    task_file=$4
    shift 4
    [[ $task =~ $slug ]] || fail "a task takes lowercase letters, digits and hyphens: $task"
    [[ -s $task_file ]] || fail "the task file is missing or empty: $task_file"
    ;;
  *) usage ;;
esac
[[ $project =~ $slug && ${#project} -le 16 ]] || fail "a project takes lowercase letters, digits and hyphens, 16 at most: $project"

cwd=$PWD
machine=
title=$task
claude_args=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --cwd) cwd=${2:?--cwd needs a folder}; shift 2 ;;
    --on) machine=${2:?--on needs a machine}; shift 2 ;;
    --title) title=${2:?--title needs a text}; shift 2 ;;
    --auto) claude_args+=(--permission-mode auto); shift ;;
    *) usage ;;
  esac
done
[[ $role == orchestrator || -z $machine ]] || fail "a thread starts on its orchestrator's machine: run this there, without --on"

# The name is the terminal's name, the worktree and the file of the first message.
name=$project${task:+-$task}
((${#name} <= 32)) || fail "$name is longer than the 32 characters a terminal name takes"

# Runs one program where the session runs, with what is piped in as its input.
there() {
  hc exec ${machine:+--on "$machine"} --cwd "$cwd" --stdin -- "$@"
}

there true </dev/null 2>/dev/null || fail "cannot use the folder $cwd${machine:+ on $machine}"

# The live terminals on the session's machine, as hc lists them, filtered by what comes after.
here() {
  hc ls --json "$@" | jq -c --arg machine "$machine" '
    .terminals[]
    | select(if $machine == "" then (.address | contains("/") | not) else (.address | startswith($machine + "/")) end)'
}

# The project's orchestrator is found by its labels, not by its name: a project can be renamed.
orchestrator=$(here --label "project=$project" --label role=orchestrator | jq -sc '.[0] // empty')
lead=$(jq -r '.address // empty' <<<"$orchestrator")

if [[ $role == orchestrator && -n $lead ]]; then
  [[ $(jq -r '.agent' <<<"$orchestrator") != claude-code ]] || fail "the orchestrator of $project is running already as $lead"
  # A terminal without Claude is a leftover shell, unless it is so new that Claude is still starting.
  age=$(hc get "$lead" --json | jq --argjson now "$(date +%s)" '$now - (.created_ms / 1000 | floor)')
  ((age > starting_seconds)) || fail "the orchestrator of $project is starting as $lead: wait a moment"
  hc kill "$lead" >/dev/null
  hc rm "$lead" >/dev/null 2>&1 || true
fi
if [[ $role == thread && -z $lead ]]; then
  fail "no orchestrator of $project runs here: start it first"
fi
# hc takes one live terminal of a name. Another one with this name is not ours to end.
[[ -z $(here | jq -r --arg name "$name" 'select(.name == $name) | .address') ]] || fail "a terminal named $name runs already"

# shellcheck disable=SC2016
free_gib=$(there sh -c 'command -v free >/dev/null && free -g | awk "/^Mem:/{print \$7}"' </dev/null || true)
if [[ $free_gib =~ ^[0-9]+$ ]] && ((free_gib < min_free_gib)); then
  fail "only $free_gib GiB of memory is free${machine:+ on $machine}: close idle sessions first"
fi
# shellcheck disable=SC2016
there sh -c 'f=$HOME/.claude/gateway-settings.json; [ ! -f "$f" ] || sh -c "$(jq -r .apiKeyHelper "$f")" >/dev/null 2>&1' </dev/null ||
  fail "the Claude gateway token helper fails${machine:+ on $machine}: sign in there first"

# shellcheck disable=SC2016
COPYFILE_DISABLE=1 tar --no-xattrs -C "$kit" -cf - . |
  there sh -c 'mkdir -p "$HOME/$1" && tar -C "$HOME/$1" -xf -' sh "$installed"

first_message() {
  if [[ $role == orchestrator ]]; then
    echo "You are the orchestrator of the project \`$project\`. Do the steps of \"When you start\" now."
    return
  fi
  cat -- "$task_file"
}
# shellcheck disable=SC2016
first_message | there sh -c 'mkdir -p "$HOME/.claude/briefs" && cat > "$HOME/.claude/briefs/$1.md"' sh "$name"

run_args=(run --json --bg --keep --name "$name" --cwd "$cwd" --label "project=$project" --label "role=$role")
if [[ $role == thread ]]; then
  # A thread outlives a restart of its orchestrator. Its tab is in its orchestrator's space, so
  # Herdr's own rename and close work on it.
  run_args+=(--outlive-parent --label "task=$task" --label "title=$title")
  space=$(hc get "$lead" --json | jq -r '.labels["herdr.space"] // empty')
  if there git rev-parse --git-dir </dev/null >/dev/null 2>&1; then
    claude_args+=(--worktree "$name")
  fi
else
  # An orchestrator belongs to the person, not to the session that started it. Its tab is in a space of its own.
  run_args+=(--no-parent)
  space=sp$name
fi
if [[ -n $space ]]; then
  run_args+=(--label "herdr.space=$space" --label "herdr.tab=tb$name")
fi

# A login zsh has the user's Claude setup. `exec` keeps Claude the terminal's
# program, so Herdr shows its status.
# shellcheck disable=SC2016
launch='role=$1 name=$2 kit=$HOME/$3
shift 3
set -- --append-system-prompt-file "$kit/$role.md" "$@"
gateway=$HOME/.claude/gateway-settings.json
if [[ -f $gateway ]]; then set -- --settings "$gateway" "$@"; fi
# `--` ends the options: a first message can start with a dash.
exec claude "$@" -- "$(<"$HOME/.claude/briefs/$name.md")"'

# `${a[@]+"${a[@]}"}` passes an empty array as nothing, also in the bash 3.2 that macOS ships.
hc "${run_args[@]}" ${machine:+--on "$machine"} -- zsh -lc "$launch" zsh "$role" "$name" "$installed" ${claude_args[@]+"${claude_args[@]}"} |
  jq -r '"started \(.name) as terminal \(.address)"'
