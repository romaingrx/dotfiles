{
  config,
  dotfilesPath,
  pkgs,
  ...
}:
let
  theme = import ../../../lib/theme;
in
{
  home = {
    packages = [ pkgs.tmux ];
    file.".config/tmux".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/tmux";
  };

  # Sourced by config/tmux/tmux.conf before the Catppuccin plugin loads.
  xdg.configFile."theme/tmux.conf".text = ''
    set -g @catppuccin_flavor '${theme.flavor}'
  '';
}
