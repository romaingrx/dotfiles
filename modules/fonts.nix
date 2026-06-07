# Shared font installation for every machine (NixOS and nix-darwin both expose
# `fonts.packages`). The set of packages is derived from the theme font
# contract in lib/theme, so the families that apps reference are exactly the
# ones installed here — no per-host drift, no fonts referenced but missing.
{ lib, pkgs, ... }:
let
  inherit (import ../lib/theme { }) fonts;
  resolvePackage =
    font:
    lib.attrByPath (lib.splitString "." font.package)
      (throw "theme font package not found in pkgs: ${font.package}")
      pkgs;
in
{
  fonts.packages = lib.unique (map resolvePackage (lib.attrValues fonts));
}
