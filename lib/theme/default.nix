_:
let
  inherit (builtins)
    attrNames
    concatStringsSep
    map
    match
    stringLength
    substring
    toJSON
    toString
    ;

  mkColor = hex: rgb: {
    inherit hex rgb;
    hash = "#${hex}";
  };

  rgbTuple = color: concatStringsSep ", " (map toString color.rgb);

  hyprRgb = color: "rgb(${color.hex})";
  hyprRgba = color: alpha: "rgba(${color.hex}${alpha})";
  sketchybar = color: alpha: "0x${alpha}${color.hex}";

  hexToRgbList =
    hex:
    let
      normalized = if substring 0 1 hex == "#" then substring 1 6 hex else hex;
      pairs = [
        (substring 0 2 normalized)
        (substring 2 2 normalized)
        (substring 4 2 normalized)
      ];
      digits = {
        "0" = 0;
        "1" = 1;
        "2" = 2;
        "3" = 3;
        "4" = 4;
        "5" = 5;
        "6" = 6;
        "7" = 7;
        "8" = 8;
        "9" = 9;
        a = 10;
        b = 11;
        c = 12;
        d = 13;
        e = 14;
        f = 15;
        A = 10;
        B = 11;
        C = 12;
        D = 13;
        E = 14;
        F = 15;
      };
      fromPair =
        pair:
        let
          hi = substring 0 1 pair;
          lo = substring 1 1 pair;
        in
        digits.${hi} * 16 + digits.${lo};
    in
    assert stringLength normalized == 6;
    assert match "[0-9A-Fa-f]{6}" normalized != null;
    map fromPair pairs;

  color = hex: mkColor hex (hexToRgbList hex);

  palettes = {
    latte = {
      rosewater = color "dc8a78";
      flamingo = color "dd7878";
      pink = color "ea76cb";
      mauve = color "8839ef";
      red = color "d20f39";
      maroon = color "e64553";
      peach = color "fe640b";
      yellow = color "df8e1d";
      green = color "40a02b";
      teal = color "179299";
      sky = color "04a5e5";
      sapphire = color "209fb5";
      blue = color "1e66f5";
      lavender = color "7287fd";
      text = color "4c4f69";
      subtext1 = color "5c5f77";
      subtext0 = color "6c6f85";
      overlay2 = color "7c7f93";
      overlay1 = color "8c8fa1";
      overlay0 = color "9ca0b0";
      surface2 = color "acb0be";
      surface1 = color "bcc0cc";
      surface0 = color "ccd0da";
      base = color "eff1f5";
      mantle = color "e6e9ef";
      crust = color "dce0e8";
    };

    mocha = {
      rosewater = color "f5e0dc";
      flamingo = color "f2cdcd";
      pink = color "f5c2e7";
      mauve = color "cba6f7";
      red = color "f38ba8";
      maroon = color "eba0ac";
      peach = color "fab387";
      yellow = color "f9e2af";
      green = color "a6e3a1";
      teal = color "94e2d5";
      sky = color "89dceb";
      sapphire = color "74c7ec";
      blue = color "89b4fa";
      lavender = color "b4befe";
      text = color "cdd6f4";
      subtext1 = color "bac2de";
      subtext0 = color "a6adc8";
      overlay2 = color "9399b2";
      overlay1 = color "7f849c";
      overlay0 = color "6c7086";
      surface2 = color "585b70";
      surface1 = color "45475a";
      surface0 = color "313244";
      base = color "1e1e2e";
      mantle = color "181825";
      crust = color "11111b";
    };
  };

  aliases = palette: {
    accent = palette.mauve;
    background = palette.base;
    backgroundStrong = palette.mantle;
    backgroundSubtle = palette.surface0;
    border = palette.mauve;
    borderSecondary = palette.blue;
    borderInactive = palette.overlay0;
    cursor = palette.rosewater;
    foreground = palette.text;
    foregroundMuted = palette.subtext0;
    selectionBackground = palette.rosewater;
    selectionForeground = palette.base;
    success = palette.green;
    warning = palette.yellow;
    danger = palette.red;
    info = palette.blue;
  };

  appearances = {
    light = {
      name = "light";
      flavor = "latte";
      colorscheme = "catppuccin-latte";
      tmuxFlavor = "latte";
      palette = palettes.latte;
      aliases = aliases palettes.latte;
    };

    dark = {
      name = "dark";
      flavor = "mocha";
      colorscheme = "catppuccin-mocha";
      tmuxFlavor = "mocha";
      palette = palettes.mocha;
      aliases = aliases palettes.mocha;
    };
  };

  renderAlacritty =
    theme:
    let
      p = theme.palette;
      subtleTerminalColor = if theme.flavor == "latte" then p.overlay0 else p.subtext0;
      normalBlack = if theme.flavor == "latte" then p.subtext1 else p.surface1;
      normalWhite = if theme.flavor == "latte" then p.surface2 else p.subtext1;
      brightBlack = if theme.flavor == "latte" then p.subtext0 else p.surface2;
      brightWhite = if theme.flavor == "latte" then p.surface1 else p.subtext0;
      title = if theme.flavor == "latte" then "Latte (Light)" else "Mocha (Dark)";
    in
    ''
      # Catppuccin ${title}
      [colors.primary]
      background = "${p.base.hash}"
      foreground = "${p.text.hash}"
      dim_foreground = "${p.overlay1.hash}"
      bright_foreground = "${p.text.hash}"

      [colors.cursor]
      text = "${p.base.hash}"
      cursor = "${p.rosewater.hash}"

      [colors.vi_mode_cursor]
      text = "${p.base.hash}"
      cursor = "${p.lavender.hash}"

      [colors.search.matches]
      foreground = "${p.base.hash}"
      background = "${subtleTerminalColor.hash}"

      [colors.search.focused_match]
      foreground = "${p.base.hash}"
      background = "${p.green.hash}"

      [colors.footer_bar]
      foreground = "${p.base.hash}"
      background = "${subtleTerminalColor.hash}"

      [colors.hints.start]
      foreground = "${p.base.hash}"
      background = "${p.yellow.hash}"

      [colors.hints.end]
      foreground = "${p.base.hash}"
      background = "${subtleTerminalColor.hash}"

      [colors.selection]
      text = "${p.base.hash}"
      background = "${p.rosewater.hash}"

      [colors.normal]
      black = "${normalBlack.hash}"
      red = "${p.red.hash}"
      green = "${p.green.hash}"
      yellow = "${p.yellow.hash}"
      blue = "${p.blue.hash}"
      magenta = "${p.pink.hash}"
      cyan = "${p.teal.hash}"
      white = "${normalWhite.hash}"

      [colors.bright]
      black = "${brightBlack.hash}"
      red = "${p.red.hash}"
      green = "${p.green.hash}"
      yellow = "${p.yellow.hash}"
      blue = "${p.blue.hash}"
      magenta = "${p.pink.hash}"
      cyan = "${p.teal.hash}"
      white = "${brightWhite.hash}"

      [colors.dim]
      black = "${normalBlack.hash}"
      red = "${p.red.hash}"
      green = "${p.green.hash}"
      yellow = "${p.yellow.hash}"
      blue = "${p.blue.hash}"
      magenta = "${p.pink.hash}"
      cyan = "${p.teal.hash}"
      white = "${normalWhite.hash}"
    '';

  renderWaybarCss =
    theme:
    let
      p = theme.palette;
      a = theme.aliases;
    in
    ''
      @define-color rosewater ${p.rosewater.hash};
      @define-color flamingo ${p.flamingo.hash};
      @define-color pink ${p.pink.hash};
      @define-color mauve ${p.mauve.hash};
      @define-color red ${p.red.hash};
      @define-color maroon ${p.maroon.hash};
      @define-color peach ${p.peach.hash};
      @define-color yellow ${p.yellow.hash};
      @define-color green ${p.green.hash};
      @define-color teal ${p.teal.hash};
      @define-color sky ${p.sky.hash};
      @define-color sapphire ${p.sapphire.hash};
      @define-color blue ${p.blue.hash};
      @define-color lavender ${p.lavender.hash};
      @define-color text ${p.text.hash};
      @define-color subtext1 ${p.subtext1.hash};
      @define-color subtext0 ${p.subtext0.hash};
      @define-color overlay2 ${p.overlay2.hash};
      @define-color overlay1 ${p.overlay1.hash};
      @define-color overlay0 ${p.overlay0.hash};
      @define-color surface2 ${p.surface2.hash};
      @define-color surface1 ${p.surface1.hash};
      @define-color surface0 ${p.surface0.hash};
      @define-color base ${p.base.hash};
      @define-color mantle ${p.mantle.hash};
      @define-color crust ${p.crust.hash};
      @define-color foreground ${a.foreground.hash};
      @define-color background ${a.background.hash};
      @define-color accent ${a.accent.hash};
    '';

  renderHyprland =
    theme:
    let
      a = theme.aliases;
    in
    ''
      $theme_active_border = ${hyprRgba a.border "ee"} ${hyprRgba a.borderSecondary "ee"} 45deg
      $theme_inactive_border = ${hyprRgba a.borderInactive "aa"}

      general {
          col.active_border = $theme_active_border
          col.inactive_border = $theme_inactive_border
      }
    '';

  renderHyprlock =
    theme:
    let
      a = theme.aliases;
    in
    ''
      $color = ${hyprRgb a.background}
      $inner_color = rgba(${a.background.hex}cc)
      $outer_color = ${hyprRgb a.foreground}
      $font_color = ${hyprRgb a.foreground}
      $check_color = ${hyprRgb a.accent}
    '';

  renderRofi =
    theme:
    let
      a = theme.aliases;
    in
    ''
      * {
        theme-bg: ${a.background.hash};
        theme-fg: ${a.foreground.hash};
        theme-muted: ${a.foregroundMuted.hash};
        theme-accent: ${a.accent.hash};
        theme-selected-fg: ${a.background.hash};
      }
    '';

  renderSketchybar =
    theme:
    let
      p = theme.palette;
      a = theme.aliases;
    in
    ''
      #!/usr/bin/env sh

      BLACK=${sketchybar p.mantle "ff"}
      WHITE=${sketchybar p.text "ff"}
      RED=${sketchybar p.red "ff"}
      GREEN=${sketchybar p.green "ff"}
      BLUE=${sketchybar p.blue "ff"}
      YELLOW=${sketchybar p.yellow "ff"}
      ORANGE=${sketchybar p.peach "ff"}
      MAGENTA=${sketchybar p.mauve "ff"}
      GREY=${sketchybar p.overlay2 "ff"}
      TRANSPARENT=0x00000000

      STATUS_BG=${sketchybar a.background "22"}
      STATUS_GRAPH_BG=${sketchybar a.background "16"}
      BAR_BG=${sketchybar a.background "15"}
      POPUP_BG=${sketchybar a.background "70"}
      FOCUS_BG=${sketchybar p.surface2 "55"}
      BUSY_BG=${sketchybar p.surface2 "22"}
      MODE_BG=${sketchybar p.mauve "24"}
      RED_GRAPH_FILL=${sketchybar p.red "20"}
      BLUE_GRAPH_FILL=${sketchybar p.blue "20"}
      GREEN_GRAPH_FILL=${sketchybar p.green "20"}
    '';

  renderTmux = theme: ''
    set -g @catppuccin_flavor '${theme.tmuxFlavor}'
  '';

  renderMetadata =
    theme:
    toJSON {
      inherit (theme)
        name
        flavor
        colorscheme
        tmuxFlavor
        ;
      palette = builtins.mapAttrs (_: c: c.hash) theme.palette;
      aliases = builtins.mapAttrs (_: c: c.hash) theme.aliases;
    };

  generatedArtifacts = theme: {
    "alacritty.toml" = renderAlacritty theme;
    "waybar-colors.css" = renderWaybarCss theme;
    "hyprland-theme.conf" = renderHyprland theme;
    "hyprlock-theme.conf" = renderHyprlock theme;
    "rofi-theme.rasi" = renderRofi theme;
    "sketchybar-colors.sh" = renderSketchybar theme;
    "tmux-theme.conf" = renderTmux theme;
    "theme.json" = renderMetadata theme;
  };
in
{
  inherit
    appearances
    generatedArtifacts
    hyprRgb
    hyprRgba
    palettes
    rgbTuple
    sketchybar
    ;

  appearanceNames = attrNames appearances;
}
