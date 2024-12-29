return {
  black = 0xff181819,
  white = 0xffffffff,
  red = 0xfffc5d7c,
  green = 0xff9ed072,
  blue = 0xff76cce0,
  yellow = 0xffe7c664,
  orange = 0xfff39660,
  magenta = 0xffb39df3,
  grey = 0xff7f8490,
  transparent = 0x00000000,

  bar = {
    bg = 0x40000000,
    border = 0xff2c2e34,
  },
  popup = {
    bg = 0xc02c2e34,
    border = 0xff7f8490
  },
  bg1 = 0xff363944,
  bg2 = 0xff414550,

  workspace = {
    active = 0xffefbaff,
    inactive = 0x44ffffff,
    border = 0x44ffffff,
  },

  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then return color end
    local bit32 = require("bit32")
    return bit32.bor(
      bit32.band(color, 0x00ffffff),
      bit32.lshift(math.floor(alpha * 255.0), 24)
    )
  end,
} 