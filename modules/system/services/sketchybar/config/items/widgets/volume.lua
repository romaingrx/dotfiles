local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

local volume = sbar.add("item", "volume", {
  position = "right",
  icon = {
    font = {
      family = "SF Symbols",
      style = settings.font.style_map["Regular"],
      size = 16.0,
    },
  },
  label = {
    font = { family = settings.font.numbers },
  },
})

volume:subscribe("volume_change", function(env)
  local vol = tonumber(env.INFO)
  local icon = icons.volume._0

  if vol > 66 then
    icon = icons.volume._100
  elseif vol > 33 then
    icon = icons.volume._66
  elseif vol > 10 then
    icon = icons.volume._33
  elseif vol > 0 then
    icon = icons.volume._10
  end

  volume:set({
    icon = { string = icon },
    label = { string = vol .. "%" },
  })
end)

-- Initial volume
sbar.exec("osascript -e 'output volume of (get volume settings)'", function(vol)
  volume:set({
    icon = { string = icons.volume._100 },
    label = { string = vol .. "%" },
  })
end) 