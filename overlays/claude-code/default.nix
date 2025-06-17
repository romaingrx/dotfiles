{
  lib,
  buildNpmPackage,
  fetchzip,
}:

(import ./package.nix) { inherit lib buildNpmPackage fetchzip; }
