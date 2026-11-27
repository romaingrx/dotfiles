# Baton: the projects layout and mod of the Herdr app, kept in a repository of
# their own. The app loads the mod from a clone of it, so a build there applies
# at once. The layout is a copy that the app owns: the mod rewrites it as it runs.
{
  home-manager.sharedModules = [
    (
      {
        lib,
        config,
        pkgs,
        ...
      }:
      let
        repository = "https://github.com/romaingrx/baton.git";
        clone = "${config.home.homeDirectory}/dev/baton";
        app = "${config.home.homeDirectory}/.config/herdr-app";
      in
      {
        home.file.".config/herdr-app/mods/projects".source =
          config.lib.file.mkOutOfStoreSymlink "${clone}/mods/projects";

        home.activation.baton = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          if [ ! -e ${lib.escapeShellArg clone} ]; then
            GIT_TERMINAL_PROMPT=0 run ${lib.getExe pkgs.git} clone ${repository} ${lib.escapeShellArg clone} ||
              warnEcho "baton is not cloned: clone ${repository} to ${clone}"
          fi
          if [ ! -e ${lib.escapeShellArg "${app}/layouts/projects.json"} ] && [ -e ${lib.escapeShellArg "${clone}/layouts/projects.json"} ]; then
            run mkdir -p ${lib.escapeShellArg "${app}/layouts"}
            run cp ${lib.escapeShellArg "${clone}/layouts/projects.json"} ${lib.escapeShellArg "${app}/layouts/projects.json"}
          fi
        '';
      }
    )
  ];
}
