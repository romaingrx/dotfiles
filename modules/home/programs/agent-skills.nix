{
  config,
  lib,
  dotfilesPath,
  ...
}:
let
  mkSubdirSymlinks = import ../../../lib/mkSubdirSymlinks.nix { inherit lib config; };

  # One vendor-neutral source of truth, fanned out to each agent's skills
  # directory. Author a skill once in config/agents/skills/<name>/SKILL.md and
  # `git add` it (the flake only sees tracked files); it is symlinked into every
  # dir below on every host, with no edit here (open/closed). Machine-local and
  # `npx skills` installs are left untouched.
  source = {
    repoDir = ../../../config/agents/skills;
    liveDir = "${dotfilesPath}/config/agents/skills";
    requireFile = "SKILL.md"; # skip empty / malformed skill folders
  };

  # Each agent reads its own global skills directory. `~/.agents/skills` is the
  # shared project-style location (and Cline's global dir); other agents read
  # their own and must be listed explicitly. Add an agent by appending its dir.
  agentSkillDirs = [
    ".agents/skills" # shared / project convention (Cline global)
    ".claude/skills" # Claude Code
    ".codex/skills" # Codex
    # ".cursor/skills" ".gemini/skills" ".config/opencode/skills" — add as used
  ];
in
{
  # Per-skill symlinks (not a whole-directory link) so each agent dir stays a
  # real, multi-source directory and coexists with `npx skills` / find-skills
  # installs and any machine-local skills dropped in directly.
  home.file = lib.mkMerge (
    map (target: mkSubdirSymlinks (source // { inherit target; })) agentSkillDirs
  );

  # Links target the live checkout (the MAIN checkout via dotfilesPath), so warn
  # at switch time if it is missing — e.g. activating from a worktree before
  # merging — to make dangling links obvious instead of silent.
  home.activation.agentSkillsSourceCheck = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    if [ ! -d ${lib.escapeShellArg source.liveDir} ]; then
      printf 'agent-skills: source %s is missing; skill symlinks will dangle until it exists.\n' ${lib.escapeShellArg source.liveDir} >&2
    fi
  '';
}
