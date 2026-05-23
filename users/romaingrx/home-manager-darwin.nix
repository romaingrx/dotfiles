{
  pkgs,
  lib,
  config,
  dotfilesPath,
  ...
}:
let
  askpass = pkgs.writeShellScriptBin "askpass" ''
    /usr/bin/osascript -e 'Tell application "System Events" to display dialog "'"$1"'" default answer "" with hidden answer' -e 'text returned of result'
  '';
in
lib.mkIf pkgs.stdenv.isDarwin {
  home = {
    packages = [ askpass ];
    sessionVariables = {
      SUDO_ASKPASS = "${askpass}/bin/askpass";
    };
    sessionPath = [ "$HOME/.local/bin" ];
    file.".config/sketchybar".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/sketchybar";
  };

  launchd.agents.alacritty-theme-switcher = {
    enable = true;
    config = {
      Label = "com.romaingrx.alacritty-theme-switcher";
      ProgramArguments = [
        "${pkgs.bash}/bin/bash"
        "${config.home.homeDirectory}/.config/alacritty/theme-switcher.sh"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/alacritty-theme-switcher.log";
      StandardErrorPath = "/tmp/alacritty-theme-switcher.err";
    };
  };
}
