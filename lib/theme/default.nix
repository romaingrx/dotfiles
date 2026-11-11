# The one place colors and fonts are defined. Change `flavor` and rebuild to
# re-theme everything (latte is light, mocha is dark).
#
# Apps with an official Catppuccin port (Alacritty, tmux, Neovim, hunk) only
# take the flavor name. The rest read hex values from `palette`. Fragments that
# an editable config in config/ sources are written to ~/.config/theme/.
let
  flavor = "mocha";
  palette = (import ./catppuccin.nix).${flavor};

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

  letters = s: builtins.genList (i: builtins.substring i 1 s) (builtins.stringLength s);
  upper = builtins.replaceStrings (letters "abcdefghijklmnopqrstuvwxyz") (
    letters "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  );
in
{
  inherit flavor palette roles;

  # roleVars FORMAT: the roles as THEME_<ROLE> variables for the bar scripts,
  # each hex value written by FORMAT.
  roleVars =
    format:
    builtins.listToAttrs (
      map (role: {
        name = "THEME_${upper role}";
        value = format roles.${role};
      }) (builtins.attrNames roles)
    );

  font = {
    family = "FiraCode Nerd Font";
    package = "nerd-fonts.fira-code";
  };
}
