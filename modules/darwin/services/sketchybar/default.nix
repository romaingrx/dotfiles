{
  homeDirectory,
  lib,
  pkgs,
  ...
}:
let
  userName = builtins.baseNameOf homeDirectory;
  configDirectory = "${homeDirectory}/.config/sketchybar";
  appFont = pkgs.sketchybar-app-font;

  # The CPU, memory and network graphs (config/sketchybar/items/stats.sh).
  stats = pkgs.writeShellApplication {
    name = "sketchybar-stats";
    runtimeInputs = [ pkgs.gawk ];
    # The script hands arrays to helpers by name (local -n), which shellcheck
    # reads as unused.
    excludeShellChecks = [ "SC2034" ];
    text = lib.concatMapStrings builtins.readFile [
      ../../../../config/statusbar/graph.sh
      ../../../../config/sketchybar/providers/stats.sh
    ];
  };
in
{
  services.sketchybar = {
    enable = true;
    package = pkgs.sketchybar;
    config = ''
      #!${pkgs.bash}/bin/bash
      export CONFIG_DIR="${configDirectory}"
      export SKETCHYBAR_APP_FONT_PATH="${appFont}/share/fonts/truetype/sketchybar-app-font.ttf"
      export SKETCHYBAR_APP_ICON_MAP="${appFont}/bin/icon_map.sh"
      exec "${configDirectory}/sketchybarrc"
    '';
    extraPackages = with pkgs; [
      lua5_4
      jq
      tree
      appFont
      stats
    ];
  };

  fonts.packages = [ appFont ];

  launchd.user.agents.sketchybar.serviceConfig.EnvironmentVariables = {
    HOME = homeDirectory;
    USER = userName;
    LOGNAME = userName;
    SKETCHYBAR_APP_FONT_PATH = "${appFont}/share/fonts/truetype/sketchybar-app-font.ttf";
    SKETCHYBAR_APP_ICON_MAP = "${appFont}/bin/icon_map.sh";
  };
  launchd.user.agents.sketchybar.serviceConfig.ProcessType = "Interactive";
}
