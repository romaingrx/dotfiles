# The one place colors and fonts are defined. Change `flavor` and rebuild to
# re-theme everything (latte is light, mocha is dark).
#
# Apps with an official Catppuccin port (tmux, Neovim, hunk) only
# take the flavor name. The rest read hex values from `palette`. Fragments that
# an editable config in config/ sources are written to ~/.config/theme/.
# Ghostty is the exception: it switches between latte and mocha by itself to
# follow the OS light/dark appearance.
let
  flavor = "mocha";
in
{
  inherit flavor;
  palette = (import ./catppuccin.nix).${flavor};

  font = {
    family = "FiraCode Nerd Font";
    package = "nerd-fonts.fira-code";
  };
}
