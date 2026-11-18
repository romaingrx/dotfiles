# A status bar script (config/waybar/scripts/stats.sh,
# config/sketchybar/providers/stats.sh) with the shared graph helpers
# (config/statusbar/graph.sh) prepended.
pkgs:
{
  name,
  script,
  runtimeInputs ? [ ],
  runtimeEnv ? { },
}:
pkgs.writeShellApplication {
  inherit name runtimeInputs runtimeEnv;
  # The scripts hand arrays to helpers by name (local -n), which shellcheck
  # reads as unused.
  excludeShellChecks = [ "SC2034" ];
  text = builtins.readFile ../config/statusbar/graph.sh + builtins.readFile script;
}
