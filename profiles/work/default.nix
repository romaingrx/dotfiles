{pkgs, config, ...}: {
  imports = [
    ../../modules/home/cli/git.nix
    ../../modules/home/cli/zsh.nix
    ../../modules/home/cli/tmux.nix
    ../../modules/home/desktop/alacritty.nix
    ../../modules/home/development/neovim.nix
    ../../modules/home/packages
  ];

  home.stateVersion = "24.05";

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Work-specific configurations
  programs.git = {
    userName = "Romain Graux";
    userEmail = "romain.graux@uclouvain.be";
    signing = {
      # You'll need to set up a different GPG key for work
      key = null;  # Replace with your work GPG key
      signByDefault = true;
    };
  };

  # Work SSH configuration
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "github.com" = {
        user = "git";
        identityFile = "~/.ssh/github_work";
      };
      # Add other work-specific SSH configurations here
    };
    extraConfig = ''
      UseKeychain yes
      AddKeysToAgent yes
    '';
  };

  # Work GPG configuration
  programs.gpg = {
    enable = true;
    settings = {
      trust-model = "tofu+pgp";
    };
  };
} 