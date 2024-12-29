local colors = require("colors")

-- Equivalent to the --bar domain
sbar.bar({
  height = 32,
  position = "top",
  sticky = true,
  margin = 0,
  blur_radius = 10,
  color = colors.bar.bg,
  padding_right = 10,
  padding_left = 10,
}) 