{
  format,
  mkRoles,
  palettes,
}:
{
  name,
  flavor,
  colorscheme,
  tmuxFlavor,
}:
let
  palette = palettes.${flavor};
in
{
  inherit
    colorscheme
    flavor
    format
    name
    palette
    tmuxFlavor
    ;

  roles = mkRoles { inherit flavor palette; };
}
