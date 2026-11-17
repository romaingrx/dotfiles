return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Mojo LSP configuration
        mojo = {},
      },
    },
  },

  -- Setup filetype detection for .mojo and .🔥 files
  {
    "neovim/nvim-lspconfig",
    init = function()
      vim.filetype.add({
        extension = {
          mojo = "mojo",
          ["🔥"] = "mojo",
        },
      })
    end,
  },

  -- Configure formatter
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
    },
  },
}
