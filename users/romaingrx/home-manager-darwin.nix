{
  pkgs,
  lib,
  config,
  ...
}:
(lib.mkIf pkgs.stdenv.isDarwin {
  home.file.".config/sketchybar".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/config/sketchybar";

})
