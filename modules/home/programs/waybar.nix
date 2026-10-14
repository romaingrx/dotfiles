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
            months = span p.rosewater;
            weekdays = span p.yellow;
            today = span p.red;
          };
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

          * {
            font-family: "${theme.font.family}";
          }
        '';
      };
    };
  };
}
