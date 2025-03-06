{ pkgs, ... }: {
  home.packages = with pkgs; [ ripgrep bat ];

  programs.nixvim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    luaLoader.enable = true;
    globals.mapleader = " "; # Set leader key to space

    extraPlugins = with pkgs.vimPlugins; [ nvim-web-devicons ];

    colorschemes.catppuccin.enable = true;

    opts = {
      number = true; # Show line numbers
      relativenumber = true; # Show relative line numbers
      shiftwidth = 2; # Number of spaces for auto indent
      tabstop = 2; # Number of spaces that <Tab> counts for
      expandtab = true; # Use spaces instead of tabs
      smartindent = true; # Smart autoindenting
      wrap = false; # Don't wrap lines
      swapfile = false; # Don't use swapfile
      backup = false; # Don't create backup files
      undofile = true; # Persistent undo
      hlsearch = true; # Highlight search results
      ignorecase = true; # Ignore case when searching
      smartcase = true; # Don't ignore case when search pattern has uppercase
      termguicolors = true; # True color support
      updatetime = 100; # Faster completion
      scrolloff = 8; # Lines of context
      sidescrolloff = 8; # Columns of context
      cursorline = true; # Highlight the current line
      signcolumn = "yes"; # Always show signcolumn
    };

    plugins = {
      toggleterm.enable = true;
      web-devicons.enable = true;
      treesitter.enable = true;

      telescope = {
        enable = true;
        keymaps = {
          "<leader>ff" = "find_files";
          "<leader>fg" = "live_grep";
          "<leader>fb" = "buffers";
          "<leader>fh" = "help_tags";
        };
        settings.defaults = {
          file_ignore_patterns = [
            "^.git/"
            "^.mypy_cache/"
            "^__pycache__/"
            "^output/"
            "^data/"
            "%.ipynb"
          ];
          set_env.COLORTERM = "truecolor";
        };
      };

      nvim-autopairs.enable = true;
      which-key.enable = true;
    };

    extraConfigLua = ''
      -- Highlight on yank
      vim.api.nvim_create_autocmd("TextYankPost", {
        callback = function()
          vim.highlight.on_yank({ timeout = 200 })
        end,
      })
    '';
  };
}
