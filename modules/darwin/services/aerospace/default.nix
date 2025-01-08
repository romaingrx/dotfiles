{ pkgs, ... }: {
  enable = true;
  package = pkgs.aerospace;
  settings = pkgs.lib.importTOML ./aerospace.toml;
}