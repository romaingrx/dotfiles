#!/usr/bin/env bash
# Links each skill in agents/skills into ~/.agents/skills, and links each folder
# in agents/mirrors back to it, for hosts without home-manager: cloud agent
# sessions and devcontainers. Nix hosts get the same links from
# modules/home/programs/agent-skills.nix.
#
# Claude Code prefers a personal skill to a project skill with the same name.
# So a skill that the current project also ships is unlinked, and the project
# copy wins. The project is $CLAUDE_PROJECT_DIR (set in hooks), else $PWD.
#
# A setup that runs once (cloud setup script, devcontainer.sh) cannot know the
# project, so it passes --install-hook to run sync.sh again at each session.
#
# Usage: agents/sync.sh [--install-hook] [--pull]
#   --install-hook  write a SessionStart hook that runs `sync.sh --pull` into
#                   ~/.claude/settings.json, if that file does not exist yet.
#   --pull          fast-forward this checkout first, for the hook.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
project="${CLAUDE_PROJECT_DIR:-$PWD}"

for arg in "$@"; do
  case "$arg" in
  --install-hook)
    settings="$HOME/.claude/settings.json"
    if grep -qsF "$root/sync.sh" "$settings"; then
      true
    elif [[ -e "$settings" ]]; then
      echo "agents/sync.sh: $settings exists; add the SessionStart hook by hand" >&2
    else
      mkdir -p "$HOME/.claude"
      cat >"$settings" <<EOF
{"hooks":{"SessionStart":[{"matcher":"startup|resume","hooks":[{"type":"command","command":"$root/sync.sh --pull"}]}]}}
EOF
    fi
    ;;
  --pull)
    git -C "$root" pull --ff-only --quiet ||
      echo "agents/sync.sh: pull failed, linking the current checkout" >&2
    ;;
  *)
    echo "agents/sync.sh: unknown option $arg" >&2
    exit 2
    ;;
  esac
done

# True when the project has its own skill called $1, not one of our links.
project_ships() {
  local dir
  for dir in "$project/.claude/skills/$1" "$project/.agents/skills/$1"; do
    if [[ -e "$dir" && "$(readlink -f "$dir")" != "$root/skills/$1" ]]; then
      return 0
    fi
  done
  return 1
}

hub="$HOME/.agents/skills"
mirrors=()
while IFS= read -r line; do
  if [[ -n "$line" && "$line" != \#* ]]; then mirrors+=("$HOME/$line"); fi
done <"$root/mirrors"

for dir in "$hub" "${mirrors[@]}"; do
  # A whole-folder link from an older setup dangles after a move; replace it.
  if [[ -L "$dir" && ! -e "$dir" ]]; then rm "$dir"; fi
  mkdir -p "$dir"
done
for skill in "$root"/skills/*/; do
  skill="${skill%/}"
  name="${skill##*/}"
  if project_ships "$name"; then
    for dir in "$hub" "${mirrors[@]}"; do
      if [[ -L "$dir/$name" ]]; then rm "$dir/$name"; fi
    done
  elif [[ -f "$skill/SKILL.md" ]]; then
    ln -sfn "$skill" "$hub/$name"
    for dir in "${mirrors[@]}"; do
      ln -sfn "$hub/$name" "$dir/$name"
    done
  fi
done
