{
  lib,
  pkgs,
  config,
  dotfilesPath,
  ...
}:
let
  theme = import ../../../lib/theme;

  # Copy the Catppuccin port matching the macOS appearance to the file that
  # config/alacritty/alacritty.toml imports last. Alacritty live-reloads it.
  syncAppearance = pkgs.writeShellScript "alacritty-appearance" ''
    if [[ $(/usr/bin/defaults read -g AppleInterfaceStyle 2>/dev/null) == "Dark" ]]; then
      flavor=mocha
    else
      flavor=latte
    fi
    src="$HOME/.config/alacritty/themes/catppuccin-$flavor.toml"
    dst="$HOME/.config/theme/alacritty-appearance.toml"
    cmp -s "$src" "$dst" || cat "$src" >"$dst"
  '';
in
{
  home = {
    packages = [ pkgs.alacritty ];
    file.".config/alacritty".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/alacritty";
  };

  # Imported by config/alacritty/alacritty.toml: the official Catppuccin port
  # for the configured flavor, plus the theme font.
  xdg.configFile."theme/alacritty.toml".text = ''
    ${builtins.readFile ../../../config/alacritty/themes/catppuccin-${theme.flavor}.toml}
    [font.normal]
    family = "${theme.font.family}"
  '';

  # macOS writes the global preferences plist on every light/dark switch, and
  # launchd runs the sync then (and at login). Nothing stays running.
  launchd.agents.alacritty-appearance = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [ "${syncAppearance}" ];
      WatchPaths = [ "${config.home.homeDirectory}/Library/Preferences/.GlobalPreferences.plist" ];
      RunAtLoad = true;
    };
  };
}
