return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "biome" },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        biome = {},
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        typescript = { "biome", "biome-organize-imports" },
        javascript = { "biome", "biome-organize-imports" },
        typescriptreact = { "biome", "biome-organize-imports" },
        javascriptreact = { "biome", "biome-organize-imports" },
        astro = { "biome", "biome-organize-imports" },
        json = { "biome" },
        jsonc = { "biome" },
      },
    },
  },
}
