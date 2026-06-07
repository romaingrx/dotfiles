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
  renderTheme = import ./rofi/theme.nix { inherit lib; };
  rofiConfigRoot = "${config.home.homeDirectory}/.config/rofi";
  runtimeRofiRoot = themeLib.currentAppDir "rofi";
  generatedArtifacts = themeLib.generatedArtifacts "rofi" (appearanceTheme: {
    "config.rasi" = renderTheme.config appearanceTheme;
  });
in
{
  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home = {
      activation.romaingrxRofiThemeLinks = themeLib.currentSymlinkActivation {
        links = {
          "${rofiConfigRoot}/config.rasi" = "${runtimeRofiRoot}/config.rasi";
        };
      };

      file = generatedArtifacts;
    };
  };
}
