{
  config,
  lib,
  dotfilesPath,
  ...
}:
let
  mkSubdirSymlinks = import ../../../lib/mkSubdirSymlinks.nix { inherit lib config; };
  mkSourceCheck = import ../../../lib/mkSourceCheck.nix { inherit lib; };

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

  # `~/.agents/skills` is the shared location most agents read (Pi, Cline).
  # Claude Code reads only its own dir, so it is listed explicitly.
  agentSkillDirs = [
    ".agents/skills" # shared convention (Pi, Cline)
    ".claude/skills" # Claude Code
    # add an agent's own dir here only if it ignores ~/.agents/skills
  ];
in
{
  # Per-skill symlinks (not a whole-directory link) so each agent dir stays a
  # real, multi-source directory and coexists with `npx skills` / find-skills
  # installs and any machine-local skills dropped in directly.
  home.file = lib.mkMerge (
    map (target: mkSubdirSymlinks (source // { inherit target; })) agentSkillDirs
  );

  # Links target the MAIN checkout via dotfilesPath, not the active worktree.
  home.activation.agentSkillsSourceCheck = mkSourceCheck {
    label = "agent-skills";
    dir = source.liveDir;
  };
}
