{ pkgs, ... }:
let
  theme = import ../../../lib/theme { };
  # Seed the launchd service with the dark (default) appearance. The runtime
  # 70-borders reload hook re-colors a running instance to track the active
  # appearance after a theme apply, so this only sets the boot-time colors.
  seed = theme.appearances.dark;
  inherit (seed) format;
  ui = seed.roles.ui;
in
{
  enable = true;
  package = pkgs.jankyborders;
  active_color = format.argb ui.border "ff";
  inactive_color = format.argb ui.borderInactive "ff";
  width = 5.0;
}
