# Keeps a clone of each repository in dotfiles.clones at its path. A path that
# is there is left as it is: the clone is the person's to change.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  clone =
    name:
    { url, path }:
    ''
      if [ ! -e ${lib.escapeShellArg path} ]; then
        GIT_TERMINAL_PROMPT=0 run ${lib.getExe pkgs.git} clone ${lib.escapeShellArg url} ${lib.escapeShellArg path} ||
          warnEcho ${lib.escapeShellArg "${name} is not cloned: clone ${url} to ${path}"}
      fi
    '';
in
{
  options.dotfiles.clones = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          url = lib.mkOption {
            type = lib.types.str;
            description = "Where the repository is cloned from.";
          };
          path = lib.mkOption {
            type = lib.types.str;
            description = "The folder of the clone.";
          };
        };
      }
    );
    default = { };
    description = "Repositories that are cloned at activation when their folder is missing.";
  };

  config.home.activation.clones = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    lib.concatStrings (lib.mapAttrsToList clone config.dotfiles.clones)
  );
}
