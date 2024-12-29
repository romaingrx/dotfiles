local colors = require("colors")
local settings = require("settings")

local front_app = sbar.add("item", "front_app", {
  position = "left",
  padding_left = 10,
  icon = { drawing = false },
  label = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Bold"],
      size = 13.0,
    },
  },
  updates = true,
})

front_app:subscribe("front_app_switched", function(env)
  front_app:set({ label = env.INFO })
end) 