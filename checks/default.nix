{ pkgs, ... }@args:
let
  checkModules = [
    ./pre-commit.nix
    ./theme.nix
  ];
in
pkgs.lib.mergeAttrsList (map (checkModule: import checkModule args) checkModules)
