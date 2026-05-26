{ homeDirectory, pkgs, ... }:
let
  userName = builtins.baseNameOf homeDirectory;
  configDirectory = "${homeDirectory}/.config/sketchybar";
  appFont = pkgs.sketchybar-app-font;
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
