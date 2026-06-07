# Typography for the theme contract.
#
# Fonts are appearance-independent: they do not change between light and dark,
# so they live here at the top level rather than inside a palette. Each entry
# pairs the family name (consumed by every app's generated theme fragment) with
# the nixpkgs attribute path that provides it (resolved by modules/fonts.nix and
# installed once per machine). Keeping both in one place means a font that is
# referenced is always installed, and vice versa.
_: {
  monospace = {
    family = "FiraCode Nerd Font";
    package = "nerd-fonts.fira-code";
  };
}
