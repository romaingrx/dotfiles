{
  pkgs,
  lib,
  config,
  ...
}:
let
  askpass = pkgs.writeShellScriptBin "askpass" ''
    /usr/bin/osascript -e 'Tell application "System Events" to display dialog "'"$1"'" default answer "" with hidden answer' -e 'text returned of result'
  '';
in
(lib.mkIf pkgs.stdenv.isDarwin {
  home.packages = [ askpass ];

  home.sessionVariables = {
    SUDO_ASKPASS = "${askpass}/bin/askpass";
  };

  home.file.".config/sketchybar".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/config/sketchybar";

  home.sessionPath = [ "$HOME/.local/bin" ];

})
