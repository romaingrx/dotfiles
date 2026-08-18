# Out-of-store link source check.
# Warns at switch time when the source directory is missing — activating from a
# worktree, say — so links fail loudly instead of dangling in silence.
#
# Usage example:
# home.activation.fooSourceCheck = mkSourceCheck {
#   label = "foo";
#   dir = "${dotfilesPath}/config/foo";
# };
{
  lib,
  ...
}:

{
  # Warning prefix, conventionally the module name.
  label,

  # Directory the links point at.
  dir,
}:

lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
  if [ ! -d ${lib.escapeShellArg dir} ]; then
    printf '%s: source %s is missing; links dangle until it exists.\n' \
      ${lib.escapeShellArg label} ${lib.escapeShellArg dir} >&2
  fi
''
