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
in
{
  config = lib.mkIf pkgs.stdenv.isLinux {
    home.file =
      lib.genAttrs'
        (lib.filter (lib.hasSuffix ".conf") (lib.attrNames (builtins.readDir ../../../config/hypr)))
        (
          name:
          lib.nameValuePair ".config/hypr/${name}" {
            source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/hypr/${name}";
          }
        );

    # Sourced by config/hypr/hyprland-core.conf and hyprlock.conf.
    xdg.configFile = {
      "theme/hyprland.conf".text = ''
        general {
            col.active_border = rgba(${p.mauve}ee) rgba(${p.blue}ee) 45deg
            col.inactive_border = rgba(${p.overlay0}aa)
        }
      '';

      "theme/hyprlock.conf".text = ''
        $color = rgb(${p.base})
        $inner_color = rgb(${p.mantle})
        $outer_color = rgb(${p.mauve})
        $font_color = rgb(${p.text})
        $font_family = ${theme.font.family}
        $check_color = rgb(${p.blue})
      '';
    };
  };
}
