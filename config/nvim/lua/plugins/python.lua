return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ruff_lsp = {},
        basedpyright = {},
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "ruff_format", "ruff_organize_imports", "ruff_fix" },
      },
    },
  },
  {
    "jpalardy/vim-slime",
    init = function()
      vim.g.slime_target = "tmux"
      vim.g.slime_default_config = { socket_name = "default", target_pane = "{last}" }
      vim.g.slime_dont_ask_default = 1
    end,
  },
  {
    "hanschen/vim-ipython-cell",
    dependencies = { "jpalardy/vim-slime" },
    ft = "python",
    keys = {
      { "<leader>xr", "<cmd>IPythonCellExecuteCell<cr>", desc = "Execute Cell" },
      { "<leader>xj", "<cmd>IPythonCellExecuteCellJump<cr>", desc = "Execute Cell & Jump" },
      { "[c", "<cmd>IPythonCellPrevCell<cr>", desc = "Previous Cell" },
      { "]c", "<cmd>IPythonCellNextCell<cr>", desc = "Next Cell" },
    },
  },
}
