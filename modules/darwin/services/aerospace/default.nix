# Static settings live in aerospace.toml. Workspace rules and launch keys are
# built from lib/apps, so swapping an app never touches this config.
{ pkgs }:
let
  inherit (pkgs) lib;
  apps = import ../../../../lib/apps;
  toml = lib.importTOML ./aerospace.toml;

  # Where each app category goes.
  workspaces = {
    agent = "1";
    terminal = "C";
    editor = "C";
    browser = "B";
    social = "S";
    utility = "U";
    music = "M";
  };

  open = app: "exec-and-forget open -b ${app.bundleId}";
  toWorkspace = app: {
    "if".app-id = app.bundleId;
    run = "move-node-to-workspace ${workspaces.${app.category}}";
  };
  placed = lib.filterAttrs (_: app: app ? bundleId && workspaces ? ${app.category}) apps.catalog;
in
{
  enable = true;
  package = pkgs.aerospace;
  settings = lib.recursiveUpdate toml {
    mode.main.binding = {
      alt-shift-t = open apps.terminal;
      alt-shift-d = open apps.browser.darwin;
    };
    on-window-detected = map toWorkspace (lib.attrValues placed) ++ toml.on-window-detected;
  };
}
