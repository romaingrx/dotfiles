{ pkgs, inputs, config, ... }: {
  imports = [
    ../../modules/common
    ../../modules/secrets
    ./gpg.nix
    ./rust.nix
    ./home-manager-nixos.nix
  ];

  # Use the modern secrets management system
  mySecrets = {
    enable = true;
    defaultSopsFile = ./secrets/secrets.yaml;

    userSecrets = {
      "gpg_github_private_key" = {
        path = "${config.home.homeDirectory}/.config/gnupg/private.key";
        sopsFile = ./secrets/gpg.yaml;
        mode = "0600";
      };

      "ssh_github_private_key" = {
        path = "${config.home.homeDirectory}/.ssh/github";
        sopsFile = ./secrets/ssh.yaml;
        mode = "0600";
      };
    };

    # Example template for complex configurations
    templates = {
      "git-config" = {
        content = ''
          [user]
              name = "Romain Graux"
              email = "${config.sops.placeholder."git/email"}"
              signingkey = "${config.sops.placeholder."git/signing_key"}"
          [commit]
              gpgsign = true
        '';
        path = "${config.home.homeDirectory}/.gitconfig.secret";
        mode = "0644";
      };
    };
  };

  # Enable the new configuration options with clean structure
  myConfig = {
    common = {
      enable = true;
      stateVersion = "24.11";
    };

    # User packages (Home Manager) - categorized and feature-based
    packages = {
      enable = true;
      core.enable = true;
      development.enable = true;
      productivity.enable = true;
      media.enable = true;
      extraPackages = with pkgs; [
        inputs.nixvim.packages.${system}.default
        ollama
        tor
        mitmproxy
        brave
        tailscale
        claude-code
      ];
    };

    # Programs with modern abstractions
    programs = {
      enable = true;
      git = {
        enable = true;
        userName = "Romain Graux";
        userEmail = "48758915+romaingrx@users.noreply.github.com";
        signing = {
          key = "EE706544613BE505";
          signByDefault = true;
        };
      };
      zsh = {
        enable = true;
        features = {
          development = true;
          productivity = true;
        };
      };
      tmux.enable = true;
      gpg.enable = true;
      ssh.enable = true;
    };

    # System packages (environment.systemPackages)
    systemPackages = {
      enable = true;
      core.enable = true;
      development.enable = true;
    };
  };

  # Compatibility configuration for original git.nix
  home.github.gpg = {
    key = "EE706544613BE505";
    email = "48758915+romaingrx@users.noreply.github.com";
  };

  # Enhanced activation script for GPG key import using modern patterns
  home.activation = {
    importGpgKey = let
      gpg = "${pkgs.gnupg}/bin/gpg";
      exportGPGTTY = "export GPG_TTY=$(tty)";
    in ''
      # Ensure proper GPG environment
      ${exportGPGTTY}
      if [ -f "${config.mySecrets.userSecrets.gpg_github_private_key.path}" ]; then
        # Check if the key is already imported
        if ! ${gpg} --list-secret-keys | grep -q "EE706544613BE505"; then
          echo "Importing GPG key..."
          $DRY_RUN_CMD ${gpg} --batch --import "${config.mySecrets.userSecrets.gpg_github_private_key.path}"
        else
          echo "GPG key already imported, skipping..."
        fi
      fi
    '';
  };
}
