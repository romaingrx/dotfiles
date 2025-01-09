{ pkgs, ... }: {
  enable = true;
  shell = "${pkgs.zsh}/bin/zsh";
  terminal = "tmux-256color";
  plugins = with pkgs; [
    tmuxPlugins.better-mouse-mode
    # tmuxPlugins.vim-tmux-navigator
    {
      plugin = tmuxPlugins.catppuccin;
      extraConfig = '' 
        set -g @catppuccin_flavour 'latte'
        set -g @catppuccin_window_tabs_enabled on
        set -g @catppuccin_date_time "%H:%M"
      '';
    }
    {
      plugin = tmuxPlugins.resurrect;
      extraConfig = ''
        set -g @resurrect-strategy-vim 'session'
        set -g @resurrect-strategy-nvim 'session'
        set -g @resurrect-capture-pane-contents 'on'
      '';
    }
    {
      plugin = tmuxPlugins.continuum;
      extraConfig = ''
        set -g @continuum-restore 'on'
        set -g @continuum-boot 'on'
        set -g @continuum-save-interval '10'
      '';
    }
  ];
  extraConfig = ''
  '';
}
