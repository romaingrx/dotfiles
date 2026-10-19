{
  config,
  dotfilesPath,
  lib,
  pkgs,
  ...
}:
let
  theme = import ../../../lib/theme;
  p = theme.palette;
  link = name: config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/waybar/${name}";
  span = color: "<span color='#${color}'><b>{}</b></span>";

  # Right-side modules, built here so they read the palette.
  stats = pkgs.writeShellApplication {
    name = "waybar-stats";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      iproute2
    ];
    runtimeEnv = {
      THEME_MUTED = p.overlay1;
      THEME_ACCENT = p.mauve;
      THEME_WARNING = p.peach;
      THEME_DANGER = p.red;
      THEME_SECONDARY = p.teal;
    };
    # The script hands arrays to helpers by name (local -n), which shellcheck
    # reads as unused.
    excludeShellChecks = [ "SC2034" ];
    text = builtins.readFile ../../../config/waybar/scripts/stats.sh;
  };

  # The Tailscale logo, a 3x3 grid of dots with a lit T.
  logo =
    name: lit: dim:
    let
      dot =
        x: y: on:
        ''<circle cx="${toString x}" cy="${toString y}" r="2.7" fill="#${if on then lit else dim}"/>'';
      svg = pkgs.writeText "tailscale-${name}.svg" ''
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
          ${dot 4 4 false}${dot 12 4 false}${dot 20 4 false}
          ${dot 4 12 true}${dot 12 12 true}${dot 20 12 true}
          ${dot 4 20 false}${dot 12 20 true}${dot 20 20 false}
        </svg>
      '';
    in
    pkgs.runCommand "tailscale-${name}.png" { nativeBuildInputs = [ pkgs.librsvg ]; } ''
      rsvg-convert --width 48 --height 48 ${svg} --output $out
    '';

  tailscaleStatus = pkgs.writeShellApplication {
    name = "waybar-tailscale";
    runtimeInputs = [
      pkgs.jq
      pkgs.tailscale
    ];
    runtimeEnv = {
      TAILSCALE_ON = "${logo "on" p.text p.surface2}";
      TAILSCALE_OFF = "${logo "off" p.surface2 p.surface1}";
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
          include = [ "${config.xdg.configHome}/waybar/config-base.jsonc" ];
          clock.calendar.format = {
            months = span p.mauve;
            weekdays = span p.subtext0;
            today = span p.red;
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
          @define-color theme_bg #${p.base};
          @define-color theme_fg #${p.text};
          @define-color theme_muted #${p.subtext0};
          @define-color theme_accent #${p.mauve};
          @define-color theme_warning #${p.yellow};
          @define-color theme_danger #${p.red};
          @define-color theme_surface #${p.surface0};
          @define-color theme_mantle #${p.mantle};

          * {
            font-family: "${theme.font.family}";
          }
        '';
      };
    };
  };
}
