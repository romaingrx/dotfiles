# Apps by role. ./catalog.nix says what each app is, ./defaults.nix which ones
# you prefer. Consumers read the resolved defaults below or filter the catalog
# by category; how apps are installed stays with the installer.
let
  catalog = import ./catalog.nix;
  defaults = import ./defaults.nix;
in
{
  inherit catalog;
  terminal = catalog.${defaults.terminal};
  browser = builtins.mapAttrs (_: name: catalog.${name}) defaults.browser;
}
