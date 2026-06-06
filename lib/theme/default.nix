_:
let
  colors = import ./colors.nix { };
  palettes = import ./catppuccin.nix { inherit colors; };
  mkRoles = import ./roles.nix { };
  mkTheme = import ./mkTheme.nix {
    inherit (colors) format;
    inherit mkRoles palettes;
  };

  appearances = {
    light = mkTheme {
      name = "light";
      flavor = "latte";
      colorscheme = "catppuccin-latte";
      tmuxFlavor = "latte";
    };

    dark = mkTheme {
      name = "dark";
      flavor = "mocha";
      colorscheme = "catppuccin-mocha";
      tmuxFlavor = "mocha";
    };
  };
in
{
  inherit
    appearances
    colors
    mkTheme
    palettes
    ;
  inherit (colors) format;

  appearanceNames = builtins.attrNames appearances;
}
