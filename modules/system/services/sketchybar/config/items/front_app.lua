local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local theme = colors.theme

local front_app = sbar.add("item", "front_app", {
  position = "left",
  padding_left = 10,
  padding_right = 10,
  icon = {
    string = icons.app.default,
    color = theme.text.normal,
    background = theme.item.background,
  },
  label = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Bold"],
      size = 13.0,
    },
    color = theme.text.normal,
  },
  background = {
    color = theme.item.background,
    corner_radius = 5,
    drawing = true,
  },
})

front_app:subscribe("front_app_switched", function(env)
  front_app:set({ label = env.INFO })
end) 