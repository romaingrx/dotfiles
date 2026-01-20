{ pkgs, ... }:
{
  # TODO romaingrx: Get the config from the system and check automatically the app IDs
  enable = true;
  package = pkgs.aerospace;
  settings = pkgs.lib.importTOML ./aerospace.toml;
}
