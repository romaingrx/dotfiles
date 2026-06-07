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

    /bin/launchctl print "gui/$UID/org.nixos.sketchybar" >/dev/null 2>&1 || exit 0
    exec ${pkgs.sketchybar}/bin/sketchybar --reload
  '';
in
{
  config = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    home.file = generatedArtifacts // themeLib.reloadHook "50-sketchybar" reloadHook;
  };
}
