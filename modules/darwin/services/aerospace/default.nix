# Static settings live in aerospace.toml. App workspace rules and launch keys
# come from lib/apps, so swapping an app never touches this config.
{ pkgs }:
let
  inherit (pkgs) lib;
  apps = import ../../../../lib/apps;
  toml = lib.importTOML ./aerospace.toml;
  open = app: "exec-and-forget open -b ${app.bundleId}";
  toWorkspace = app: {
    "if".app-id = app.bundleId;
    run = "move-node-to-workspace ${apps.workspaces.${app.role}}";
  };
in
{
  enable = true;
  package = pkgs.aerospace;
  settings = lib.recursiveUpdate toml {
    mode.main.binding = {
      alt-shift-t = open apps.terminal;
      alt-shift-d = open apps.browser.darwin;
    };
    on-window-detected = map toWorkspace (lib.attrValues apps.catalog) ++ toml.on-window-detected;
  };
}
