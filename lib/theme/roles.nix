_:
{
  flavor,
  palette,
}:
let
  subtleTerminalColor = if flavor == "latte" then palette.overlay0 else palette.subtext0;
  normalBlack = if flavor == "latte" then palette.subtext1 else palette.surface1;
  normalWhite = if flavor == "latte" then palette.surface2 else palette.subtext1;
  brightBlack = if flavor == "latte" then palette.subtext0 else palette.surface2;
  brightWhite = if flavor == "latte" then palette.surface1 else palette.subtext0;
in
{
  ui = {
    background = palette.base;
    backgroundStrong = palette.mantle;
    backgroundSubtle = palette.surface0;
    foreground = palette.text;
    foregroundMuted = palette.subtext0;
    accent = palette.mauve;
    border = palette.mauve;
    borderSecondary = palette.blue;
    borderInactive = palette.overlay0;
    selectionBackground = palette.rosewater;
    selectionForeground = palette.base;
  };

  status = {
    success = palette.green;
    warning = palette.yellow;
    danger = palette.red;
    info = palette.blue;
  };

  terminal = {
    primary = {
      background = palette.base;
      foreground = palette.text;
      dimForeground = palette.overlay1;
      brightForeground = palette.text;
    };

    cursor = {
      text = palette.base;
      cursor = palette.rosewater;
      viModeCursor = palette.lavender;
    };

    selection = {
      text = palette.base;
      background = palette.rosewater;
    };

    search = {
      foreground = palette.base;
      background = subtleTerminalColor;
      focusedBackground = palette.green;
      hintsStartBackground = palette.yellow;
      hintsEndBackground = subtleTerminalColor;
    };

    footer = {
      foreground = palette.base;
      background = subtleTerminalColor;
    };

    normal = {
      black = normalBlack;
      inherit (palette)
        blue
        green
        red
        yellow
        ;
      cyan = palette.teal;
      magenta = palette.pink;
      white = normalWhite;
    };

    bright = {
      black = brightBlack;
      inherit (palette)
        blue
        green
        red
        yellow
        ;
      cyan = palette.teal;
      magenta = palette.pink;
      white = brightWhite;
    };

    dim = {
      black = normalBlack;
      inherit (palette)
        blue
        green
        red
        yellow
        ;
      cyan = palette.teal;
      magenta = palette.pink;
      white = normalWhite;
    };
  };
}
