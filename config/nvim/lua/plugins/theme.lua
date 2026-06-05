return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      background = {
        light = "latte",
        dark = "mocha",
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
    end,
  },
}
