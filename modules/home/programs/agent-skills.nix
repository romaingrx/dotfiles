{
  config,
  lib,
  dotfilesPath,
  ...
}:
let
  mkSubdirSymlinks = import ../../../lib/mkSubdirSymlinks.nix { inherit lib config; };

  # One vendor-neutral source of truth, fanned out to every agent's skills
  # directory. Author a skill once in config/agents/skills/<name>/ and `git add`
  # it; it is symlinked into each dir below on every host, with no edit here
  # (open/closed). Add an agent by appending its directory to the list.
  source = {
    repoDir = ../../../config/agents/skills;
    liveDir = "${dotfilesPath}/config/agents/skills";
  };
  agentSkillDirs = [
    ".agents/skills" # cross-agent canonical (Codex, Cursor, Gemini, ...)
    ".claude/skills" # Claude Code (does not read .agents/skills natively)
    # ".codex/skills" ".cursor/skills" — add per-agent dirs here as needed
  ];
in
{
  # Per-skill symlinks (not a whole-directory link) so each agent dir stays a
  # real, multi-source directory and coexists with `npx skills` / find-skills
  # installs and any machine-local skills dropped in directly.
  home.file = lib.mkMerge (
    map (target: mkSubdirSymlinks (source // { inherit target; })) agentSkillDirs
  );
}
