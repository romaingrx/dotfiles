{
  lib,
  pkgs,
  config,
  dotfilesPath,
  ...
}:
let
  theme = import ../../../lib/theme;
in
{
  # On macOS the app comes from the Homebrew cask (modules/darwin/homebrew.nix).
  home = {
    packages = lib.optionals pkgs.stdenv.isLinux [ pkgs.ghostty ];
    file.".config/ghostty".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/ghostty";
  };

  # Sourced by config/ghostty/config.
  xdg.configFile."theme/ghostty".text = ''
    font-family = ${theme.font.family}
  '';
}
