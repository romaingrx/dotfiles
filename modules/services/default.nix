{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myServices;

  # Import service creation helper
  mkService = import ../../lib/mkService.nix { inherit lib pkgs; };

in
{
  options.myServices = {
    enable = lib.mkEnableOption "custom services";

    # Service registry with type-safe options
    sketchybar = {
      enable = lib.mkEnableOption "SketchyBar status bar";
      package = lib.mkPackageOption pkgs "sketchybar" { };
      configDir = lib.mkOption {
        type = lib.types.path;
        description = "SketchyBar configuration directory";
      };
    };

    aerospace = {
      enable = lib.mkEnableOption "AeroSpace window manager";
      package = lib.mkPackageOption pkgs "aerospace" { };
      settings = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "AeroSpace configuration";
      };
    };

    jankyborders = {
      enable = lib.mkEnableOption "JankyBorders";
      package = lib.mkPackageOption pkgs "jankyborders" { };
      width = lib.mkOption {
        type = lib.types.int;
        default = 5;
        description = "Border width";
      };
      hidpi = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable HiDPI support";
      };
    };

    mitmproxy = {
      enable = lib.mkEnableOption "mitmproxy service";
      package = lib.mkPackageOption pkgs "mitmproxy" { };
      port = lib.mkOption {
        type = lib.types.int;
        default = 8080;
        description = "Proxy port";
      };
      interfaces = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "Wi-Fi" ];
        description = "Network interfaces";
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      # SketchyBar service
      (lib.mkIf (cfg.sketchybar.enable && pkgs.stdenv.isDarwin) (mkService {
        name = "sketchybar";
        description = "SketchyBar status bar";
        command = "${cfg.sketchybar.package}/bin/sketchybar";
        args = [
          "--config"
          "${cfg.sketchybar.configDir}/sketchybarrc"
        ];
        environment = {
          PATH = "${pkgs.lua}/bin:${pkgs.jq}/bin";
        };
      }))

      # AeroSpace service
      (lib.mkIf (cfg.aerospace.enable && pkgs.stdenv.isDarwin) {
        services.aerospace = {
          enable = true;
          package = cfg.aerospace.package;
          settings = cfg.aerospace.settings;
        };
      })

      # JankyBorders service
      (lib.mkIf (cfg.jankyborders.enable && pkgs.stdenv.isDarwin) (mkService {
        name = "jankyborders";
        description = "JankyBorders window borders";
        command = "${cfg.jankyborders.package}/bin/borders";
        args = [
          "width=${toString cfg.jankyborders.width}"
        ] ++ lib.optional cfg.jankyborders.hidpi "hidpi=on";
      }))

      # Mitmproxy service
      (lib.mkIf cfg.mitmproxy.enable (mkService {
        name = "mitmproxy";
        description = "Mitmproxy transparent proxy";
        command = "${cfg.mitmproxy.package}/bin/mitmproxy";
        args = [
          "--listen-port"
          (toString cfg.mitmproxy.port)
          "--set"
          "confdir=$HOME/.mitmproxy"
          "--mode"
          "regular"
          "--showhost"
        ];
        environment = {
          HOME = "$HOME";
        };
        standardOutput = "/tmp/mitmproxy.log";
        standardError = "/tmp/mitmproxy.error.log";
      }))
    ]
  );
}
