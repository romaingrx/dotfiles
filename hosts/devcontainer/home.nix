# Standalone home-manager profile for throwaway dev containers.
{ pkgs, ... }:
{
  imports = [
    ../../modules/nvim.nix
    ../../modules/home/programs/agent-skills.nix
    ../../modules/home/programs/git.nix
    ../../modules/home/programs/tmux.nix
    ../../modules/home/programs/zsh.nix
  ];

  home = {
    stateVersion = "24.11";
    packages = [ pkgs.lazygit ];
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };

  programs.home-manager.enable = true;
}
