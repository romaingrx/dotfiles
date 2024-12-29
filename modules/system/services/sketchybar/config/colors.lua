local M = {
  -- Base colors
  black = 0xff24283b,    -- Deep background
  white = 0xffa9b1d6,    -- Refined white
  red = 0xfff7768e,      -- Soft pink-red
  green = 0xff9ece6a,    -- Nature green
  blue = 0xff7aa2f7,     -- Royal blue
  yellow = 0xffe0af68,   -- Warm yellow
  orange = 0xffff9e64,   -- Sunset orange
  magenta = 0xffbb9af7,  -- Soft purple
  grey = 0xff565f89,     -- Muted blue-grey
  transparent = 0x00000000,

  -- Theme configuration
  theme = {
    -- Bar appearance
    bar = {
      background = 0x60000000,  -- Very subtle dark background
      border = 0x33ffffff,      -- Subtle white border
    },

    -- Item styling
    item = {
      background = 0x40000000,        -- Consistent dark background for all items
      background_selected = 0x80bb9af7, -- More visible purple highlight when selected
      border = 0x33ffffff,            -- Subtle white border
      border_selected = 0x80bb9af7,    -- Soft purple border highlight
    },

    -- Popup styling
    popup = {
      background = 0xf024283b,    -- Consistent with theme
      border = 0x33ffffff,        -- Matching subtle border
    },

    -- Text colors
    text = {
      normal = 0xffa9b1d6,    -- Main text
      dim = 0xcc565f89,       -- Subtle text
      disabled = 0x80565f89,  -- Very subtle text
    },

    -- Network specific colors
    network = {
      upload = 0xfff7768e,    -- Soft red for upload
      download = 0xff7aa2f7,  -- Royal blue for download
      inactive = 0xff565f89,  -- Muted state
    },
  }
}

-- Helper function to adjust alpha
function M.with_alpha(color, alpha)
  if alpha > 1.0 or alpha < 0.0 then return color end
  local bit32 = require("bit32")
  return bit32.bor(
    bit32.band(color, 0x00ffffff),
    bit32.lshift(math.floor(alpha * 255.0), 24)
  )
end

return M 