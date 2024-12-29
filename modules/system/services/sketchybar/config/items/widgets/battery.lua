local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

local battery = sbar.add("item", "battery", {
  position = "right",
  update_freq = 120,
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

battery:subscribe({"routine", "power_source_change", "system_woke"}, function()
  sbar.exec("pmset -g batt", function(batt_info)
    local icon = icons.battery._0
    local label = "?"

    local found, _, charge = batt_info:find("(%d+)%%")
    if found then
      charge = tonumber(charge)
      label = charge .. "%"

      if charge > 90 then
        icon = icons.battery._100
      elseif charge > 60 then
        icon = icons.battery._75
      elseif charge > 30 then
        icon = icons.battery._50
      elseif charge > 10 then
        icon = icons.battery._25
      end
    end

    local charging = batt_info:find("AC Power")
    if charging then
      icon = icons.battery.charging
    end

    battery:set({
      icon = { string = icon },
      label = { string = label },
    })
  end)
end) 