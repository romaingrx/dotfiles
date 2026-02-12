{ pkgs, ... }:
{
  enable = true;
  shell = "${pkgs.zsh}/bin/zsh";
  terminal = "tmux-256color";
  plugins = with pkgs; [
    {
      plugin = tmuxPlugins.catppuccin;
      extraConfig = "";
    }
    {
      plugin = tmuxPlugins.resurrect;
      extraConfig = "";
    }
    {
      plugin = tmuxPlugins.continuum;
      extraConfig = "";
    }
  ];
  extraConfig = builtins.readFile ../../../config/tmux/tmux.conf;
}
