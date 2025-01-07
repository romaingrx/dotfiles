{ config, pkgs, ... }: {
  imports = [
    ../../modules/home
  ];

  # State version
  home.stateVersion = "24.05";

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
