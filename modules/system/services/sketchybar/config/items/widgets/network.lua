local icons = require("icons")
local colors = require("colors")
local settings = require("settings")
local network = require("helpers.network")

local theme = colors.theme

local wifi_up = sbar.add("item", "widgets.wifi1", {
  position = "right",
  padding_left = -5,
  width = 0,
  icon = {
    padding_right = 0,
    font = {
      style = settings.font.style_map["Bold"],
      size = 9.0,
    },
    string = icons.wifi.upload,
    color = theme.text.normal,
  },
  label = {
    font = {
      family = settings.font.numbers,
      style = settings.font.style_map["Bold"],
      size = 9.0,
    },
    color = theme.network.upload,
    string = "0 Bps",
  },
  y_offset = 4,
  update_freq = 2.0,
})

local wifi_down = sbar.add("item", "widgets.wifi2", {
  position = "right",
  padding_left = -5,
  icon = {
    padding_right = 0,
    font = {
      style = settings.font.style_map["Bold"],
      size = 9.0,
    },
    string = icons.wifi.download,
    color = theme.text.normal,
  },
  label = {
    font = {
      family = settings.font.numbers,
      style = settings.font.style_map["Bold"],
      size = 9.0,
    },
    color = theme.network.download,
    string = "0 Bps",
  },
  y_offset = -4,
})

local wifi = sbar.add("item", "widgets.wifi.padding", {
  position = "right",
  label = { drawing = false },
})

-- Background around the item
local wifi_bracket = sbar.add("bracket", "widgets.wifi.bracket", {
  wifi.name,
  wifi_up.name,
  wifi_down.name
}, {
  background = { color = theme.item.background, corner_radius = 5 },
  popup = { 
    align = "center",
    background = {
      color = theme.popup.background,
      border_width = 2,
      border_color = theme.popup.border,
      corner_radius = 9,
      padding_left = 7,
      padding_right = 7,
    }
  }
})

local ssid = sbar.add("item", {
  position = "popup." .. wifi_bracket.name,
  icon = {
    font = {
      style = settings.font.style_map["Bold"]
    },
    string = icons.wifi.router,
    color = theme.text.normal,
  },
  width = 250,
  align = "center",
  label = {
    font = {
      size = 15,
      style = settings.font.style_map["Bold"]
    },
    color = theme.text.normal,
    max_chars = 18,
    string = "????????????",
  },
  padding_bottom = 5,
  background = {
    height = 2,
    color = theme.popup.border,
    y_offset = -15
  }
})

local function create_info_item(name, label)
  return sbar.add("item", {
    position = "popup." .. wifi_bracket.name,
    icon = {
      align = "left",
      string = label .. ":",
      width = 125,
      color = theme.text.dim,
    },
    label = {
      string = "????????????",
      width = 125,
      align = "right",
      color = theme.text.normal,
    }
  })
end

local hostname = create_info_item("hostname", "Hostname")
local ip = create_info_item("ip", "IP")
local mask = create_info_item("mask", "Subnet mask")
local router = create_info_item("router", "Router")

sbar.add("item", { position = "right", width = settings.group_paddings })

wifi_up:subscribe({ "routine", "system_woke" }, function()
  local download, upload = network.update_network("en0")
  local up_color = (upload == "0 Bps") and theme.network.inactive or theme.network.upload
  local down_color = (download == "0 Bps") and theme.network.inactive or theme.network.download
  
  wifi_up:set({
    icon = { color = up_color },
    label = {
      string = upload,
      color = up_color
    }
  })
  wifi_down:set({
    icon = { color = down_color },
    label = {
      string = download,
      color = down_color
    }
  })
end)

wifi:subscribe({"wifi_change", "system_woke"}, function(env)
  sbar.exec("ipconfig getifaddr en0", function(ip)
    local connected = not (ip == "")
    wifi:set({
      icon = {
        string = connected and icons.wifi.connected or icons.wifi.disconnected,
        color = connected and theme.text.normal or theme.network.upload,
      },
    })
  end)
end)

local function hide_details()
  wifi_bracket:set({ popup = { drawing = false } })
end

local function toggle_details()
  local should_draw = wifi_bracket:query().popup.drawing == "off"
  if should_draw then
    wifi_bracket:set({ popup = { drawing = true }})
    sbar.exec("networksetup -getcomputername", function(result)
      hostname:set({ label = { string = result, color = theme.text.normal } })
    end)
    sbar.exec("ipconfig getifaddr en0", function(result)
      ip:set({ label = { string = result, color = theme.text.normal } })
    end)
    sbar.exec("ipconfig getsummary en0 | awk -F ' SSID : '  '/ SSID : / {print $2}'", function(result)
      ssid:set({ label = { string = result, color = theme.text.normal } })
    end)
    sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Subnet mask: ' '/^Subnet mask: / {print $2}'", function(result)
      mask:set({ label = { string = result, color = theme.text.normal } })
    end)
    sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Router: ' '/^Router: / {print $2}'", function(result)
      router:set({ label = { string = result, color = theme.text.normal } })
    end)
  else
    hide_details()
  end
end

wifi_up:subscribe("mouse.clicked", toggle_details)
wifi_down:subscribe("mouse.clicked", toggle_details)
wifi:subscribe("mouse.clicked", toggle_details)
wifi:subscribe("mouse.exited.global", hide_details)

local function copy_label_to_clipboard(env)
  local label = sbar.query(env.NAME).label.value
  sbar.exec("echo \"" .. label .. "\" | pbcopy")
  sbar.set(env.NAME, { label = { string = icons.clipboard, align="center" } })
  sbar.delay(1, function()
    sbar.set(env.NAME, { label = { string = label, align = "right" } })
  end)
end

ssid:subscribe("mouse.clicked", copy_label_to_clipboard)
hostname:subscribe("mouse.clicked", copy_label_to_clipboard)
ip:subscribe("mouse.clicked", copy_label_to_clipboard)
mask:subscribe("mouse.clicked", copy_label_to_clipboard)
router:subscribe("mouse.clicked", copy_label_to_clipboard) 