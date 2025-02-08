{ config, pkgs, ... }: {
  imports = [
    ../../../modules/core/common
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
