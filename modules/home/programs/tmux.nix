{
  config,
  dotfilesPath,
  pkgs,
  ...
}:
let
  theme = import ../../../lib/theme;
  inherit (pkgs.tmuxPlugins) catppuccin resurrect continuum;
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

  # Sourced last by config/tmux/tmux.conf, after the plugin options. continuum
  # must load after catppuccin, which overwrites status-right.
  xdg.configFile."tmux-nix/plugins.conf".text = ''
    run-shell ${catppuccin.rtp}
    run-shell ${resurrect.rtp}
    run-shell ${continuum.rtp}

    # Toggle light (latte) / dark (mocha): prefix + T
    bind T if-shell '[ "$(tmux show -gv @catppuccin_flavor)" = "mocha" ]' \
      'set -g @catppuccin_flavor "latte" ; run ${catppuccin.rtp}' \
      'set -g @catppuccin_flavor "mocha" ; run ${catppuccin.rtp}'
  '';
}
