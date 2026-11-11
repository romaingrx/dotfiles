{ lib, ... }:
{
  xdg.configFile."tmux-nix/plugins.conf".text = lib.mkAfter ''
    unbind C-b
    set -g prefix C-a
    bind C-a send-prefix
  '';
}
