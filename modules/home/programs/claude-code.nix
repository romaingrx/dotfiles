{
  config,
  lib,
  dotfilesPath,
  ...
}:
let
  mkFileSymlinks = import ../../../lib/mkFileSymlinks.nix { inherit lib config; };
  mkSourceCheck = import ../../../lib/mkSourceCheck.nix { inherit lib; };

  liveDir = "${dotfilesPath}/config/agents/claude/output-styles";
in
{
  # Output styles are Claude-only, so they sit outside the vendor-neutral tree
  # agent-skills.nix fans out. Per-file links, as in that module, so a style
  # dropped in by hand coexists instead of landing inside the repo.
  home.file = mkFileSymlinks {
    repoDir = ../../../config/agents/claude/output-styles;
    target = ".claude/output-styles";
    suffix = ".md";
    inherit liveDir;
  };

  home.activation.claudeOutputStylesSourceCheck = mkSourceCheck {
    label = "claude-code";
    dir = liveDir;
  };
}
