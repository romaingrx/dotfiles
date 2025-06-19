{ config, lib, pkgs, ... }:
let cfg = config.myConfig.common;
in {
  imports = [
    ./packages.nix
    ./programs.nix
    ./system-packages.nix
    # Note: external-packages.nix is imported at system level (modules/darwin/)
  ];
  options.myConfig.common = {
    enable = lib.mkEnableOption "common configuration";

    editor = lib.mkOption {
      type = lib.types.str;
      default = "nvim";
      description = "Default editor";
    };

    stateVersion = lib.mkOption {
      type = lib.types.str;
      default = "24.11";
      description = "Home Manager state version";
    };
  };

  # Compatibility options to support the original program configurations
  options.home.github.gpg = {
    key = lib.mkOption {
      type = lib.types.str;
      description = "GPG signing key";
    };

    email = lib.mkOption {
      type = lib.types.str;
      description = "Git email address";
    };
  };

  config = lib.mkIf cfg.enable {
    home.stateVersion = cfg.stateVersion;

    home.sessionVariables = {
      EDITOR = cfg.editor;
      VISUAL = cfg.editor;
    };

    nix = {
      settings = {
        trusted-substituters = [
          "https://cache.nixos.org/"
          "https://nix-community.cachix.org"
          "https://nixpkgs-wayland.cachix.org"
        ];
      };
    };

    # Let Home Manager install and manage itself.
    programs.home-manager.enable = true;
  };
}
