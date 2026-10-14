-- Home Manager writes the flavor from lib/theme here; absent on a vanilla checkout.
local config_home = vim.env.XDG_CONFIG_HOME or vim.fn.expand("~/.config")
local ok, theme = pcall(dofile, config_home .. "/theme/nvim.lua")

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = { flavour = ok and theme.flavour or "mocha" },
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin" } },
}
