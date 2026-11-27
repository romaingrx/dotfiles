# Baton in the Herdr app of this machine. The app loads Baton's layouts and
# mods from a clone of its repository, so a build there applies at once.
# Baton's own installer puts them into the app: what Baton ships is not named here.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  installer = "${config.dotfiles.clones.baton.path}/install.sh";
in
{
  imports = [ ./clones.nix ];

  dotfiles.clones.baton = {
    url = "https://github.com/romaingrx/baton.git";
    path = "${config.home.homeDirectory}/dev/baton";
  };

  home.activation.batonInstall =
    lib.hm.dag.entryAfter
      [
        "clones"
        "linkGeneration"
      ]
      ''
        if [ -e ${lib.escapeShellArg installer} ]; then
          run ${lib.getExe pkgs.bash} ${lib.escapeShellArg installer} ||
            warnEcho "Baton is not installed into the Herdr app: its install.sh failed"
        fi
      '';
}
