{
  config,
  lib,
  dotfilesPath,
  ...
}:
let
  mkSubdirSymlinks = import ../../../lib/mkSubdirSymlinks.nix { inherit lib config; };
  mkSourceCheck = import ../../../lib/mkSourceCheck.nix { inherit lib; };

  # One vendor-neutral source of truth. Author a skill once in
  # agents/skills/<name>/SKILL.md and `git add` it (the flake only sees tracked
  # files); it is linked on every host, with no edit here (open/closed).
  # Machine-local and `npx skills` installs are left untouched.
  liveDir = "${dotfilesPath}/agents/skills";

  # `~/.agents/skills` is the hub most agents read (Codex, Pi, Cline): it links
  # to the dotfiles. Agents that ignore it are listed in agents/mirrors, and
  # their dirs link to the hub, so the hub stays the one place to look.
  hub = ".agents/skills";
  mirrors = lib.filter (line: line != "" && !lib.hasPrefix "#" line) (
    lib.splitString "\n" (builtins.readFile ../../../agents/mirrors)
  );

  linkSkills =
    target: linkRoot:
    mkSubdirSymlinks {
      repoDir = ../../../agents/skills;
      liveDir = linkRoot;
      requireFile = "SKILL.md"; # skip empty / malformed skill folders
      inherit target;
    };
in
{
  # Per-skill symlinks (not a whole-directory link) so each agent dir stays a
  # real, multi-source directory and coexists with `npx skills` / find-skills
  # installs and any machine-local skills dropped in directly.
  home.file = lib.mkMerge (
    [ (linkSkills hub liveDir) ]
    ++ map (target: linkSkills target "${config.home.homeDirectory}/${hub}") mirrors
  );

  # Links target the MAIN checkout via dotfilesPath, not the active worktree.
  home.activation.agentSkillsSourceCheck = mkSourceCheck {
    label = "agent-skills";
    dir = liveDir;
  };
}
