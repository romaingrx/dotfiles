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

  # Personal-specific configurations
  programs.git = {
    userName = "Romain Graux";
    userEmail = "48758915+romaingrx@users.noreply.github.com";
    signing = {
      key = "C52A01AE82206AB2";
      signByDefault = true;
    };
  };

  # Personal SSH configuration
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "github.com" = {
        user = "git";
        identityFile = "~/.ssh/github";
      };
    };
    extraConfig = ''
      UseKeychain yes
      AddKeysToAgent yes
    '';
  };

  # Personal GPG configuration
  programs.gpg = {
    enable = true;
    settings = {
      trust-model = "tofu+pgp";
    };
  };
} 