{
  pkgs,
  pre-commit-hooks,
  repoRoot,
  system,
  ...
}:
{
  pre-commit-check = pre-commit-hooks.lib.${system}.run {
    src = repoRoot;
    hooks = {
      nixfmt-rfc-style = {
        enable = true;
        package = pkgs.nixfmt;
        excludes = [ "third-party/" ];
      };
      deadnix.enable = true;
      statix.enable = true;
    };
  };
}
