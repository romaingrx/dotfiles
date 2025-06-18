{ config, lib, pkgs, ... }:
let cfg = config.myConfig.packages;
in {
  options.myConfig.packages = {
    enable = lib.mkEnableOption "common packages";

    development.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable development packages";
    };

    media.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable media packages";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Additional packages to install";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs;
      lib.flatten [
        # Always include base packages from original common/packages
        [
          nixfmt
          nil # Nix LSP
          sops
          docker
          docker-compose
          ffmpeg
          uv
          bun
          pnpm
          alacritty
          signal-desktop
          obsidian
          gnupg
          slack
          git-lfs
          pre-commit
          nodejs_23
          git
          curl
          wget
          just
          biome
        ]

        # Conditional package sets
        (lib.optionals cfg.development.enable [
          minikube
          kubectl
          kustomize
          kubeseal
          kubernetes-helm
          qemu
          zoxide
          terraform
          awscli
          openjdk
        ])

        (lib.optionals cfg.media.enable [
          # Media packages can be added here
        ])

        cfg.extraPackages
      ];
  };
}
