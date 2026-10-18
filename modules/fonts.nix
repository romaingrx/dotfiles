# Shared font installation for every machine (NixOS and nix-darwin both expose
# `fonts.packages`). The font comes from lib/theme, so the family that apps
# reference is exactly the one installed here.
{ lib, pkgs, ... }:
let
  inherit (import ../lib/theme) font;
in
{
  fonts.packages = [ (lib.getAttrFromPath (lib.splitString "." font.package) pkgs) ];
}
