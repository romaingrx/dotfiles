# Baton in the Herdr app of this machine. The app loads Baton's layouts and
# mods from a clone of its repository, so a build there applies at once. The
# clone is made when it is missing, and one that is there is left as it is.
# Baton's own installer puts the clone into the app: what Baton ships is not
# named here. This setup says where the app's Baton comes from, so a link of a
# mod that leads to another folder is pointed to the clone (--relink).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  repository = "https://github.com/romaingrx/baton.git";
  clone = lib.escapeShellArg "${config.home.homeDirectory}/dev/baton";
in
{
  home.activation.baton = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [ ! -e ${clone} ]; then
      GIT_TERMINAL_PROMPT=0 run ${lib.getExe pkgs.git} clone ${repository} ${clone}
    fi && run ${lib.getExe pkgs.bash} ${clone}/install.sh --relink ||
      warnEcho "Baton is not in the Herdr app: its clone or its install.sh failed"
  '';
}
