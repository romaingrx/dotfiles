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
  renderTheme = import ./hypr/theme.nix { inherit lib; };
  hyprConfigRoot = "${config.home.homeDirectory}/.config/hypr";
  runtimeHyprRoot = themeLib.currentAppDir "hypr";
  legacyHyprTargets = [
    (themeLib.configSource "hypr")
  ];
  editableHyprFiles = [
    "autostart.conf"
    "bindings.conf"
    "hypridle.conf"
    "hyprland-core.conf"
    "hyprlock.conf"
    "hyprpaper.conf"
    "media.conf"
    "rules.conf"
    "tiling.conf"
  ];
  editableConfigLinks = builtins.listToAttrs (
    map (name: {
      name = ".config/hypr/${name}";
      value.source = themeLib.outOfStoreConfig "hypr/${name}";
    }) editableHyprFiles
  );
  generatedArtifacts = themeLib.generatedArtifacts "hypr" (appearanceTheme: {
    "hyprland-colors.conf" = renderTheme.hyprland appearanceTheme;
    "hyprlock-colors.conf" = renderTheme.hyprlock appearanceTheme;
  });
in
{
  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home = {
      activation = {
        romaingrxHyprLegacyConfig = themeLib.removeLegacySymlinkActivation {
          path = hyprConfigRoot;
          expectedTargets = legacyHyprTargets;
        };

        romaingrxHyprThemeLinks = themeLib.currentSymlinkActivation {
          links = {
            "${hyprConfigRoot}/theme/hyprland-colors.conf" = "${runtimeHyprRoot}/hyprland-colors.conf";
            "${hyprConfigRoot}/theme/hyprlock-colors.conf" = "${runtimeHyprRoot}/hyprlock-colors.conf";
          };
        };
      };

      file = generatedArtifacts // editableConfigLinks;
    };
  };
}
