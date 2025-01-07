local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

local theme = colors.theme

local prev_value = 0
local alpha = 0.3 -- Smoothing factor

local cpu = sbar.add("item", "cpu", {
    position = "right",
    update_freq = 2,
    background = {color = theme.item.background, corner_radius = 5},
    icon = {
        color = theme.item.foreground,
        string = icons.cpu,
        font = {
            family = "SF Symbols",
            style = settings.font.style_map["Regular"],
            size = 16.0
        }
    },
    label = {
        font = {family = settings.font.numbers},
        color = theme.item.foreground
    }
})

cpu:subscribe("routine", function()
    sbar.exec(
        "top -l 2 -n 0 -s 0 | grep 'CPU usage' | tail -1 | awk '{print $3}' | cut -d'.' -f1",
        function(result)
            local cpu_info = tonumber(result) or 0

            -- Ensure valid range
            if cpu_info < 0 then cpu_info = 0 end
            if cpu_info > 100 then cpu_info = 100 end

            -- Apply smoothing
            local smoothed = (alpha * cpu_info) + ((1 - alpha) * prev_value)
            prev_value = smoothed
            local rounded = math.floor(smoothed + 0.5)

            -- Format label
            local label = string.format("%d%%", rounded)
            if rounded < 10 then label = " " .. label end

            cpu:set({label = {string = label}})
        end)
end)
