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
  renderTheme = import ./sketchybar/theme.nix { inherit lib; };
  generatedArtifacts = themeLib.generatedArtifacts "sketchybar" (appearanceTheme: {
    "colors.sh" = renderTheme.colors appearanceTheme;
  });
  reloadHook = ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    ${pkgs.sketchybar}/bin/sketchybar --reload >/dev/null 2>&1 || true
  '';
in
{
  config = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    home.file = generatedArtifacts // themeLib.reloadHook "sketchybar" reloadHook;
  };
}
