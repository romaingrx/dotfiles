local settings = require("settings")
local colors = require("colors")

-- Equivalent to the --default domain
sbar.default({
  updates = "when_shown",
  icon = {
    font = {
      family = "SF Symbols",
      style = "Semibold",
      size = 13.0
    },
    color = colors.white,
    padding_left = 4,
    padding_right = 4,
  },
  label = {
    font = {
      family = "SF Pro",
      style = "Semibold",
      size = 13.0
    },
    color = colors.white,
    padding_left = 4,
    padding_right = 4,
  },
  background = {
    height = 24,
    corner_radius = 5,
    border_width = 1,
  },
  padding_left = 5,
  padding_right = 5,
  scroll_texts = true,
}) 