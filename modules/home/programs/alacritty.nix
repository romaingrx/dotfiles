{ pkgs, ... }:
{
  enable = true;
  package = pkgs.alacritty;
  settings = {
    font = {
      normal = {
        family = "FiraCode Nerd Font";
        style = "Regular";
      };
      bold = {
        family = "FiraCode Nerd Font";
        style = "Bold";
      };
      italic = {
        family = "FiraCode Nerd Font";
        style = "Italic";
      };
      bold_italic = {
        family = "FiraCode Nerd Font";
        style = "Bold Italic";
      };
      size = 13.0;

      # Offset is the extra space around each character. offset.y can be thought of as modifying the line spacing
      offset = {
        x = 0;
        y = 1;
      };

      # Glyph offset determines the locations of the glyphs within their cells with the default being at the bottom.
      glyph_offset = {
        x = 0;
        y = 0;
      };
    };

    # Terminal colors
    colors = {
      primary = {
        background = "#1a1b26";
        foreground = "#c0caf5";
      };
      normal = {
        black = "#15161e";
        red = "#f7768e";
        green = "#9ece6a";
        yellow = "#e0af68";
        blue = "#7aa2f7";
        magenta = "#bb9af7";
        cyan = "#7dcfff";
        white = "#a9b1d6";
      };
      bright = {
        black = "#414868";
        red = "#f7768e";
        green = "#9ece6a";
        yellow = "#e0af68";
        blue = "#7aa2f7";
        magenta = "#bb9af7";
        cyan = "#7dcfff";
        white = "#c0caf5";
      };
    };

    # Window settings
    window = {
      padding = {
        x = 8;
        y = 8;
      };
      decorations = "none";
      opacity = 0.95;
    };
  };
}
