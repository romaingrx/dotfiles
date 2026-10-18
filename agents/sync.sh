#!/usr/bin/env bash
# Links each skill in agents/skills into the agent skill folders of $HOME, for
# hosts without home-manager: cloud agent sessions and devcontainers. Nix hosts
# get the same links from modules/home/programs/agent-skills.nix.
#
# Claude Code prefers a personal skill to a project skill with the same name.
# So a skill that the current project also ships is unlinked, and the project
# copy wins. The project is $CLAUDE_PROJECT_DIR (set in hooks), else $PWD.
#
# Usage: agents/sync.sh [--pull]
#   --pull  fast-forward this checkout first, for a SessionStart hook.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project="${CLAUDE_PROJECT_DIR:-$PWD}"

if [[ "${1:-}" == --pull ]]; then
  git -C "$root" pull --ff-only --quiet ||
    echo "agents/sync.sh: pull failed, linking the current checkout" >&2
fi

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

for target in .claude/skills .agents/skills .codex/skills; do
  mkdir -p "$HOME/$target"
  for skill in "$root"/skills/*/; do
    skill="${skill%/}"
    name="${skill##*/}"
    link="$HOME/$target/$name"
    if project_ships "$name"; then
      if [[ -L "$link" ]]; then rm "$link"; fi
    elif [[ -f "$skill/SKILL.md" ]]; then
      ln -sfn "$skill" "$link"
    fi
  done
done
