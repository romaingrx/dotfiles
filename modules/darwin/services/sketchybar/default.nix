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

  # 2.24.1 adds label.font.typographical_width, which the graphs need
  # (items/stats.sh). Builds it until the pinned nixpkgs has it.
  sketchybar =
    if lib.versionOlder pkgs.sketchybar.version "2.24.1" then
      pkgs.sketchybar.overrideAttrs (_: rec {
        version = "2.24.1";
        src = pkgs.fetchFromGitHub {
          owner = "FelixKratz";
          repo = "SketchyBar";
          rev = "v${version}";
          hash = "sha256-fEbVzafjFTigR7TjQ41gOnDpk6S4B8qCwpz890ZNgwE=";
        };
      })
    else
      pkgs.sketchybar;
  env = {
    SKETCHYBAR_APP_FONT_PATH = "${appFont}/share/fonts/truetype/sketchybar-app-font.ttf";
    SKETCHYBAR_APP_ICON_MAP = "${appFont}/bin/icon_map.sh";
  };

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
    package = sketchybar;
    config = ''
      #!${pkgs.bash}/bin/bash
      export CONFIG_DIR="${configDirectory}"
      ${lib.toShellVars env}
      export ${lib.concatStringsSep " " (lib.attrNames env)}
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

  launchd.user.agents.sketchybar.serviceConfig.EnvironmentVariables = env // {
    HOME = homeDirectory;
    USER = userName;
    LOGNAME = userName;
  };
  launchd.user.agents.sketchybar.serviceConfig.ProcessType = "Interactive";
}
