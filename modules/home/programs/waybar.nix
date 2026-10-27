{
  config,
  dotfilesPath,
  lib,
  pkgs,
  ...
}:
let
  theme = import ../../../lib/theme;
  link = name: config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/waybar/${name}";
  span = color: "<span color='#${color}'><b>{}</b></span>";

  # Defined once for the CSS (as @theme_<role>) and the scripts (as $THEME_<ROLE>).
  inherit (theme) roles;

  # Right-side modules, built here so they read the palette.
  stats = import ../../../lib/statusbar-script.nix pkgs {
    name = "waybar-stats";
    script = ../../../config/waybar/scripts/stats.sh;
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      iproute2
    ];
    runtimeEnv = theme.roleVars (hex: hex);
  };

  tailscaleLogo = import ../../../lib/tailscale-logo.nix pkgs;

  # Window-rewrite rules for the workspace app icons, generated from the app map
  # that ships with the font, so a new app needs no edit here.
  appIconRules = pkgs.writeShellApplication {
    name = "waybar-app-icons";
    runtimeInputs = [ pkgs.jq ];
    text = builtins.readFile ../../../config/waybar/scripts/app-icons.sh;
  };
  appIcons = pkgs.runCommand "waybar-app-icons.json" { } ''
    ${lib.getExe appIconRules} ${pkgs.sketchybar-app-font}/bin/icon_map.sh sketchybar-app-font > $out
  '';

  tailscaleStatus = pkgs.writeShellApplication {
    name = "waybar-tailscale";
    runtimeInputs = [
      pkgs.jq
      pkgs.tailscale
    ];
    runtimeEnv = {
      TAILSCALE_ON = "${tailscaleLogo.on}";
      TAILSCALE_OFF = "${tailscaleLogo.off}";
    };
    text = builtins.readFile ../../../config/waybar/scripts/tailscale.sh;
  };
in
{
  config = lib.mkIf pkgs.stdenv.isLinux {
    xdg.configFile = {
      "waybar/config-base.jsonc".source = link "config.jsonc";
      "waybar/style.css".source = link "style.css";

      # The editable config plus the themed calendar colors.
      "waybar/config.jsonc" = {
        # Replaces the symlink left by the old runtime theme switcher.
        force = true;
        text = builtins.toJSON {
          include = [
            "${config.xdg.configHome}/waybar/config-base.jsonc"
            "${appIcons}"
          ];
          clock.calendar.format = {
            months = span roles.accent;
            weekdays = span roles.fg;
            today = span roles.danger;
          };
          "custom/cpu".exec = "${lib.getExe stats} cpu";
          "custom/memory".exec = "${lib.getExe stats} mem";
          "custom/network".exec = "${lib.getExe stats} net";
          "image#tailscale".exec = lib.getExe tailscaleStatus;
        };
      };

      # Imported by config/waybar/style.css.
      "waybar/theme.css" = {
        force = true;
        text = ''
          ${lib.concatLines (lib.mapAttrsToList (role: hex: "@define-color theme_${role} #${hex};") roles)}

          * {
            font-family: "${theme.font.family}";
          }
        '';
      };
    };
  };
}
