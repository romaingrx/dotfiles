{
  config,
  dotfilesPath,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.romaingrx.theme;
  themeLib = import ../theme/lib.nix { inherit config dotfilesPath lib; };
  renderTheme = import ./waybar/theme.nix { inherit lib; };
  waybarConfigRoot = "${config.home.homeDirectory}/.config/waybar";
  legacyWaybarTargets = [
    "${dotfilesPath}/config/waybar"
    "${config.home.homeDirectory}/${dotfilesPath}/config/waybar"
  ];
  runtimeWaybarRoot = "${config.home.homeDirectory}/${cfg.runtimeRoot}/current/waybar";
  generatedArtifacts = themeLib.generatedArtifacts "waybar" (appearanceTheme: {
    "config.jsonc" = renderTheme.config {
      configPath = "${waybarConfigRoot}/config-base.jsonc";
      theme = appearanceTheme;
    };
    "theme.css" = renderTheme.themeCss appearanceTheme;
  });
in
{
  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home = {
      activation = {
        romaingrxWaybarLegacyConfig = themeLib.removeLegacySymlinkActivation {
          path = waybarConfigRoot;
          expectedTargets = legacyWaybarTargets;
        };

        romaingrxWaybarThemeLinks = themeLib.currentSymlinkActivation {
          links = {
            "${waybarConfigRoot}/config.jsonc" = "${runtimeWaybarRoot}/config.jsonc";
            "${waybarConfigRoot}/theme.css" = "${runtimeWaybarRoot}/theme.css";
          };
        };
      };

      file = generatedArtifacts // {
        ".config/waybar/config-base.jsonc".source =
          config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/waybar/config.jsonc";
        ".config/waybar/style.css".source =
          config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/waybar/style.css";
      };
    };
  };
}
