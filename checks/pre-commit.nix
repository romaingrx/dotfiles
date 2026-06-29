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
      statix = {
        enable = true;
        # statix's own tests fail to build on current nixpkgs; skip them (the
        # linter works). Drop the override once fixed upstream.
        package = pkgs.statix.overrideAttrs (_: {
          doCheck = false;
        });
      };
    };
  };
}
