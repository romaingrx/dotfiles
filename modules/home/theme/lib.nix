{
  config,
  dotfilesPath,
  lib,
}:
let
  cfg = config.romaingrx.theme;
  theme = import ../../../lib/theme { };
  themeLib = "${dotfilesPath}/config/bin/romaingrx-theme-lib";
in
{
  generatedArtifacts =
    appName: renderArtifacts:
    builtins.listToAttrs (
      lib.flatten (
        map (
          appearance:
          let
            renderedArtifacts = renderArtifacts theme.appearances.${appearance};
            generatedRoot = "${cfg.generatedRoot}/${appearance}/${appName}";
          in
          lib.mapAttrsToList (
            name: text:
            lib.nameValuePair "${generatedRoot}/${name}" {
              inherit text;
            }
          ) renderedArtifacts
        ) theme.appearanceNames
      )
    );

  removeLegacySymlinkActivation =
    {
      path,
      expectedTargets,
    }:
    let
      expectedTargetsList = lib.concatStringsSep " " (map lib.escapeShellArg expectedTargets);
    in
    lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      legacy_link=${lib.escapeShellArg path}
      if [ -L "$legacy_link" ]; then
        current_target="$(readlink "$legacy_link")"
        for expected_target in ${expectedTargetsList}; do
          if [ "$current_target" = "$expected_target" ]; then
            rm "$legacy_link"
            break
          fi
        done
      fi
    '';

  currentSymlinkActivation =
    { links }:
    let
      linkCommands = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          link: target: "theme_link_atomic ${lib.escapeShellArg target} ${lib.escapeShellArg link}"
        ) links
      );
    in
    lib.hm.dag.entryAfter
      [
        "linkGeneration"
        "romaingrxThemeBootstrap"
      ]
      ''
        # shellcheck source=/dev/null
        source "${themeLib}"
        ${linkCommands}
      '';
}
