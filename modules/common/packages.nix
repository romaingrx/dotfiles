{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myConfig.packages;
in
{
  options.myConfig.packages = {
    enable = lib.mkEnableOption "user packages";

    # User application categories
    core.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable core user applications";
    };

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

    productivity.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable productivity applications";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Additional packages to install";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      with pkgs;
      lib.flatten [
        # Core user applications (essential tools)
        (lib.optionals cfg.core.enable [
          git
          curl
          wget
          gnupg
          sops
          just
          biome
          nil # Nix LSP
          nixfmt
        ])

        # Development packages
        (lib.optionals cfg.development.enable [
          # Development tools
          git-lfs
          pre-commit
          uv
          bun
          pnpm
          nodejs_23

          # Infrastructure tools
          docker
          docker-compose
          terraform
          awscli
          openjdk
          zoxide

          # Kubernetes tools
          minikube
          kubectl
          kustomize
          kubeseal
          kubernetes-helm
          qemu
        ])

        # Productivity applications
        (lib.optionals cfg.productivity.enable [
          alacritty
          signal-desktop
          obsidian
          slack
        ])

        # Media packages
        (lib.optionals cfg.media.enable [ ffmpeg ])

        cfg.extraPackages
      ];
  };
}
