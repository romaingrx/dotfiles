{ lib, config, ... }:
{
  options = {
    tmux-navigator.enable = lib.mkEnableOption "Enable tmux-navigator module";
  };
  config = lib.mkIf config.tmux-navigator.enable {
    plugins.tmux-navigator = {
      enable = true;
      settings = {
        disable_when_zoomed = 1;
        no_mappings = 0;
      };
    };

    # Override tmux-navigator mappings in terminal buffers to allow Ctrl+L to work
    extraConfigLua = ''
      -- Disable tmux-navigator in terminal buffers so Ctrl+L can clear screen
      vim.api.nvim_create_autocmd("TermOpen", {
        callback = function()
          vim.keymap.set("t", "<C-h>", "<C-h>", { buffer = true })
          vim.keymap.set("t", "<C-j>", "<C-j>", { buffer = true })
          vim.keymap.set("t", "<C-k>", "<C-k>", { buffer = true })
          vim.keymap.set("t", "<C-l>", "<C-l>", { buffer = true })
        end,
      })
    '';
  };
}
