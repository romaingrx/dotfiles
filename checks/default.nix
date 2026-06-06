{
  pkgs,
  pre-commit-hooks,
  repoRoot,
  system,
}:
let
  preCommitChecks = import ./pre-commit.nix {
    inherit
      pkgs
      pre-commit-hooks
      repoRoot
      system
      ;
  };
  themeChecks = import ./theme.nix {
    inherit pkgs repoRoot;
  };
in
preCommitChecks // themeChecks
