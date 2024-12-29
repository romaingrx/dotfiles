local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

local prev_in = 0
local prev_out = 0
local prev_time = 0

local function format_speed(speed)
  if speed > 1048576 then  -- 1MB/s
    return string.format("%.1fMB/s", speed/1048576)
  elseif speed > 1024 then  -- 1KB/s
    return string.format("%.1fKB/s", speed/1024)
  else
    return string.format("%dB/s", speed)
  end
end

local network = sbar.add("item", "network", {
  position = "right",
  update_freq = 2,
  icon = {
    string = icons.wifi.connected,
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

network:subscribe("routine", function()
  sbar.exec("netstat -bI en0 | grep -e 'en0'", function(result)
    local bytes_in = tonumber(result:match("%s+(%d+)%s+%d+%s+%d+%s+%d+%s+%d+%s+")) or 0
    local bytes_out = tonumber(result:match("%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+(%d+)")) or 0
    
    local current_time = os.time()
    local time_diff = current_time - prev_time
    if time_diff == 0 then time_diff = 1 end

    local speed_in = (bytes_in - prev_in) / time_diff
    local speed_out = (bytes_out - prev_out) / time_diff

    prev_in = bytes_in
    prev_out = bytes_out
    prev_time = current_time

    local label = string.format("↓%s ↑%s", 
      format_speed(speed_in),
      format_speed(speed_out)
    )

    network:set({
      label = { string = label },
      icon = { 
        string = speed_in + speed_out > 0 and icons.wifi.connected or icons.wifi.disconnected 
      },
    })
  end)
end) 