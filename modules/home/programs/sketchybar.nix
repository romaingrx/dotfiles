{ lib, pkgs, ... }:
let
  theme = import ../../../lib/theme;
  p = theme.palette;
  argb = alpha: hex: "0x${alpha}${hex}";
in
{
  # Sourced by config/sketchybar/colors.sh.
  xdg.configFile."theme/sketchybar.sh" = lib.mkIf pkgs.stdenv.isDarwin {
    text = lib.toShellVars {
      BLACK = argb "ff" p.mantle;
      WHITE = argb "ff" p.text;
      RED = argb "ff" p.red;
      GREEN = argb "ff" p.green;
      BLUE = argb "ff" p.blue;
      YELLOW = argb "ff" p.yellow;
      ORANGE = argb "ff" p.peach;
      MAGENTA = argb "ff" p.mauve;
      GREY = argb "ff" p.overlay2;
      TRANSPARENT = argb "00" p.base;
      BAR_BG = argb "15" p.base;
      STATUS_BG = argb "22" p.base;
      STATUS_GRAPH_BG = argb "16" p.base;
      POPUP_BG = argb "70" p.base;
      SPACE_INITIAL_BG = argb "44" p.text;
      SPACE_FOCUSED_BG = argb "55" p.text;
      SPACE_VISIBLE_BG = argb "22" p.text;
      MODE_BG = argb "24" p.mauve;
      CPU_SYSTEM_FILL = argb "20" p.red;
      CPU_USER_FILL = argb "20" p.blue;
      NET_DOWNLOAD_FILL = argb "20" p.blue;
      NET_UPLOAD_FILL = argb "20" p.green;
      DEFAULT_ICON_COLOR = argb "ff" p.text;
      DEFAULT_LABEL_COLOR = argb "ff" p.text;
      FONT = theme.font.family;
      NERD_FONT = theme.font.family;
    };
  };
}
