{ config, lib, pkgs, ... }:
let cfg = config.myConfig.systemPackages;
in {
  options.myConfig.systemPackages = {
    enable = lib.mkEnableOption "system packages";

    core.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable core system infrastructure packages";
    };

    development.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable development system packages";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Additional system packages";
    };
  };

  config = lib.mkIf cfg.enable {
    # System packages are added through Home Manager when using home-manager.users.<user>
    # but directly to environment.systemPackages when used at system level
    home.packages = with pkgs;
      lib.flatten [
        # Core system infrastructure (always needed)
        (lib.optionals cfg.core.enable [ git gnupg nixpkgs-fmt ])

        # Development system packages (when needed)
        (lib.optionals cfg.development.enable [ nix-prefetch-git gh ])

        # Platform-specific packages
        (lib.optionals pkgs.stdenv.isDarwin [ raycast ])

        cfg.extraPackages
      ];

    home.shellAliases =
      lib.mkIf cfg.enable { nixvim = "nix run ~/.config/nix/nixvim#default"; };
  };
}
