# The one place colors and fonts are defined. Change `flavor` and rebuild to
# re-theme everything (latte is light, mocha is dark).
#
# Apps with an official Catppuccin port (Alacritty, tmux, Neovim, hunk) only
# take the flavor name. The rest read hex values from `palette`. Fragments that
# an editable config in config/ sources are written to ~/.config/theme/.
let
  flavor = "mocha";
  palette = (import ./catppuccin.nix).${flavor};
in
{
  inherit flavor palette;

  # What each color means on the status bars (waybar and sketchybar).
  roles = with palette; {
    bg = base;
    fg = text;
    muted = overlay1;
    accent = mauve;
    secondary = teal;
    warning = peach;
    danger = red;
    surface = surface0;
    inherit mantle;
  };

  font = {
    family = "FiraCode Nerd Font";
    package = "nerd-fonts.fira-code";
  };
}
