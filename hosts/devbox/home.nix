# Trajectory Labs dev box: devcontainer plus work tooling. No age key here.
{ pkgs, inputs, ... }:
let
  master = inputs.nixpkgs-master.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [
    ../devcontainer/home.nix
    ../../modules/home/tl.nix
  ];

  home.packages = [
    master.uv
    master.gh
  ];

  programs.git.settings.user.name = "Romain Graux";
}
