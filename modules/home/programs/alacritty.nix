{
  pkgs,
  config,
  dotfilesPath,
  lib,
  ...
}:
let
  cfg = config.romaingrx.theme;
  theme = import ../../../lib/theme { };
  renderTheme = import ./alacritty/theme.nix { };
  themeArtifact =
    appearance:
    lib.nameValuePair "${cfg.generatedRoot}/${appearance}/alacritty.toml" {
      text = renderTheme theme.appearances.${appearance};
    };
in
{
  home.packages = [ pkgs.alacritty ];

  home.file = {
    ".config/alacritty".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/alacritty";
  }
  // lib.optionalAttrs cfg.enable (builtins.listToAttrs (map themeArtifact theme.appearanceNames));
}
