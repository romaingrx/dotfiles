# Trajectory Labs dev box (Ubuntu, reached over SSM): the devcontainer profile
# plus work tooling. Standalone home-manager touches only $HOME, so the box's
# managed /etc files and systemd units stay as provisioned. No sops age key here:
# sessions are recorded and AWS admins can reach the box.
{ pkgs, inputs, ... }:
let
  # Same picks as modules/home/packages.nix (see the nixpkgs-master input).
  master = inputs.nixpkgs-master.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [ ../devcontainer/home.nix ];

  home.packages = with pkgs; [
    awscli2
    ssm-session-manager-plugin
    master.uv
    master.gh
    jujutsu
  ];

  # `tl` telemetry and the dev box guide key on the work address, which stays
  # out of this public repo: put `[user] email = ...` in the included file.
  programs.git.settings = {
    user.name = "Romain Graux";
    include.path = "~/.config/git/work.gitconfig";
  };
}
