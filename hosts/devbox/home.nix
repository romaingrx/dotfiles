# Trajectory Labs dev box: devcontainer plus work tooling. No age key here.
{ pkgs, inputs, ... }:
let
  master = inputs.nixpkgs-master.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [ ../devcontainer/home.nix ];

  home.packages = with pkgs; [
    awscli2
    master.uv
    master.gh
    jujutsu
  ];

  # Work email lives in the included file, not in this public repo.
  programs.git.settings = {
    user.name = "Romain Graux";
    include.path = "~/.config/git/work.gitconfig";
  };
}
