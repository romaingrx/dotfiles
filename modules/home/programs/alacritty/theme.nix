_: theme:
let
  t = theme.roles.terminal;
  f = theme.format;
  flavorTitles = {
    latte = "Latte (Light)";
    mocha = "Mocha (Dark)";
  };
  title = flavorTitles.${theme.flavor} or "Unknown Flavor (${theme.flavor})";
in
''
  # Catppuccin ${title}
  [colors.primary]
  background = "${f.hex t.primary.background}"
  foreground = "${f.hex t.primary.foreground}"
  dim_foreground = "${f.hex t.primary.dimForeground}"
  bright_foreground = "${f.hex t.primary.brightForeground}"

  [colors.cursor]
  text = "${f.hex t.cursor.text}"
  cursor = "${f.hex t.cursor.cursor}"

  [colors.vi_mode_cursor]
  text = "${f.hex t.cursor.text}"
  cursor = "${f.hex t.cursor.viModeCursor}"

  [colors.search.matches]
  foreground = "${f.hex t.search.foreground}"
  background = "${f.hex t.search.background}"

  [colors.search.focused_match]
  foreground = "${f.hex t.search.foreground}"
  background = "${f.hex t.search.focusedBackground}"

  [colors.footer_bar]
  foreground = "${f.hex t.footer.foreground}"
  background = "${f.hex t.footer.background}"

  [colors.hints.start]
  foreground = "${f.hex t.search.foreground}"
  background = "${f.hex t.search.hintsStartBackground}"

  [colors.hints.end]
  foreground = "${f.hex t.search.foreground}"
  background = "${f.hex t.search.hintsEndBackground}"

  [colors.selection]
  text = "${f.hex t.selection.text}"
  background = "${f.hex t.selection.background}"

  [colors.normal]
  black = "${f.hex t.normal.black}"
  red = "${f.hex t.normal.red}"
  green = "${f.hex t.normal.green}"
  yellow = "${f.hex t.normal.yellow}"
  blue = "${f.hex t.normal.blue}"
  magenta = "${f.hex t.normal.magenta}"
  cyan = "${f.hex t.normal.cyan}"
  white = "${f.hex t.normal.white}"

  [colors.bright]
  black = "${f.hex t.bright.black}"
  red = "${f.hex t.bright.red}"
  green = "${f.hex t.bright.green}"
  yellow = "${f.hex t.bright.yellow}"
  blue = "${f.hex t.bright.blue}"
  magenta = "${f.hex t.bright.magenta}"
  cyan = "${f.hex t.bright.cyan}"
  white = "${f.hex t.bright.white}"

  [colors.dim]
  black = "${f.hex t.dim.black}"
  red = "${f.hex t.dim.red}"
  green = "${f.hex t.dim.green}"
  yellow = "${f.hex t.dim.yellow}"
  blue = "${f.hex t.dim.blue}"
  magenta = "${f.hex t.dim.magenta}"
  cyan = "${f.hex t.dim.cyan}"
  white = "${f.hex t.dim.white}"
''
