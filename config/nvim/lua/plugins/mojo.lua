return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        mojo = {},
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        mojo = { "mojo_format" },
      },
      formatters = {
        mojo_format = {
          command = "mojo",
          args = { "format", "$FILENAME" },
          stdin = false,
        },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
    },
  },
}
