# Trajectory Labs dev box, the SRE agent's own Linux user.
{ pkgs, inputs, ... }:
let
  master = inputs.nixpkgs-master.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [
    ../devcontainer/home.nix
    ../../modules/home/tl.nix
    ../../modules/home/programs/tmux-ctrl-a.nix
  ];

  home = {
    packages = [ master.uv ];
    sessionVariables.DD_SITE = "us5.datadoghq.com";
  };

  programs.zsh.initContent = ''
    [[ -r ~/.config/sre/env ]] && source ~/.config/sre/env
  '';

  programs.git.settings.user.name = "Romain Graux";
}
