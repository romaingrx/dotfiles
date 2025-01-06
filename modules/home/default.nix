{ pkgs, config, ... }: {
  imports = [
    ./packages
    ./programs
  ];
  home.stateVersion = "24.05"; # Please read the comment before changing.

  home.file = { };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
