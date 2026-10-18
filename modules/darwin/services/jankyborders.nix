{ pkgs, ... }:
let
  inherit (import ../../../lib/theme) palette;
in
{
  enable = true;
  package = pkgs.jankyborders;
  active_color = "0xff${palette.mauve}";
  inactive_color = "0xff${palette.overlay0}";
  width = 5.0;
}
