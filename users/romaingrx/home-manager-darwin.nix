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
    # The MAS Tailscale app bundles the CLI but never links it onto PATH.
    shellAliases.tailscale = "/Applications/Tailscale.app/Contents/MacOS/Tailscale";
    file.".config/sketchybar".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/sketchybar";
  };

  # screencapture.location and the dock persistent-others entry both point at
  # ~/Pictures/screenshots; create it so a fresh host does not silently fall back
  # to ~/Desktop for screenshots.
  home.activation.ensureScreenshotDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${config.home.homeDirectory}/Pictures/screenshots"
  '';

  launchd.agents.appearance-theme-switcher = {
    enable = true;
    config = {
      Label = "com.romaingrx.appearance-theme-switcher";
      ProgramArguments = [
        "${pkgs.bash}/bin/bash"
        "${config.home.homeDirectory}/.local/bin/romaingrx-theme-watch"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/appearance-theme-switcher.log";
      StandardErrorPath = "/tmp/appearance-theme-switcher.err";
    };
  };
}
