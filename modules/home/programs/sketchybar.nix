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
in
{
  config = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    home.file = generatedArtifacts;
  };
}
