{config, pkgs, ...}: {
  imports = [
    ../../modules/home/cli
    ../../modules/home/desktop
    ../../modules/home/development
  ];

  # Work profile-specific configuration
  programs.git = {
    userName = "Romain Graux";
    userEmail = "WORK_EMAIL"; # TODO: Replace with work email
    signing = {
      # TODO: Replace with work GPG key
      key = null;
      signByDefault = true;
    };
  };

  # Work SSH configuration
  programs.ssh = {
    matchBlocks = {
      "github.com" = {
        user = "git";
        identityFile = "~/.ssh/github_work";
      };
      # Add other work-specific SSH configurations here
    };
  };

  # State version
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
} 