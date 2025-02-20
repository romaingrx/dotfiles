{ pkgs, ... }: {
  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    plugins = with pkgs.vimPlugins; [ nvim-treesitter telescope-nvim ];
    extraConfig = ''
      set number
      set relativenumber
      set autoindent
      set tabstop=4
      set shiftwidth=4
      set expandtab
    '';
  };
}