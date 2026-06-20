_:
let
  colors = import ./colors.nix { };
  fonts = import ./fonts.nix { };
  palettes = import ./catppuccin.nix { inherit colors; };
  mkRoles = import ./roles.nix { };
  mkTheme = import ./mkTheme.nix {
    inherit (colors) format;
    inherit fonts mkRoles palettes;
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
  inherit appearances fonts;

  appearanceNames = builtins.attrNames appearances;
}
