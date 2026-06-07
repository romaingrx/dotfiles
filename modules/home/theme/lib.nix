{
  config,
  dotfilesPath,
  lib,
}:
let
  cfg = config.romaingrx.theme;
  theme = import ../../../lib/theme { };
  themeLib = "${dotfilesPath}/config/bin/romaingrx-theme-lib";
  isOrderedHookName = name: builtins.match "[0-9][0-9]-[-A-Za-z0-9._]+" name != null;
  dotfilesRoot =
    if lib.hasPrefix "/" dotfilesPath then
      dotfilesPath
    else
      "${config.home.homeDirectory}/${dotfilesPath}";
  configSource = path: "${dotfilesRoot}/config/${path}";
  outOfStoreConfig = path: config.lib.file.mkOutOfStoreSymlink (configSource path);

  # Single source of truth for the theme CLI commands: their names, where they
  # are installed, and how consumers reference them by path.
  themeBinDir = ".local/bin";
  themeCommandNames = [
    "romaingrx-theme-apply"
    "romaingrx-theme-get"
    "romaingrx-theme-lib"
    "romaingrx-theme-set"
    "romaingrx-theme-watch"
  ];
  themeBin = name: "${config.home.homeDirectory}/${themeBinDir}/${name}";
  themeCommandFiles = builtins.listToAttrs (
    map (
      name: lib.nameValuePair "${themeBinDir}/${name}" { source = outOfStoreConfig "bin/${name}"; }
    ) themeCommandNames
  );

  # Runtime `current` theme tree and a consumer's slice of it. Pairs with
  # generatedArtifacts: appName here matches the appName passed there.
  absoluteRuntimeRoot = "${config.home.homeDirectory}/${cfg.runtimeRoot}";
  currentRoot = "${absoluteRuntimeRoot}/current";
  currentAppDir = appName: "${currentRoot}/${appName}";
in
{
  inherit
    configSource
    currentAppDir
    currentRoot
    dotfilesRoot
    outOfStoreConfig
    themeBin
    themeBinDir
    themeCommandFiles
    themeCommandNames
    ;

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

  reloadHook =
    name: text:
    let
      hookName =
        assert lib.assertMsg (isOrderedHookName name)
          "Theme reload hooks must be named like '50-consumer' for deterministic ordering.";
        name;
    in
    {
      "${cfg.reloadHooksRoot}/${hookName}" = {
        inherit text;
        executable = true;
      };
    };

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
          link: target:
          let
            escapedTarget = lib.escapeShellArg target;
          in
          ''
            if [ ! -e ${escapedTarget} ]; then
              printf 'Missing theme target: %s\n' ${escapedTarget} >&2
              exit 1
            fi
            theme_link_atomic ${escapedTarget} ${lib.escapeShellArg link}
          ''
        ) links
      );
    in
    lib.hm.dag.entryBetween
      [ "romaingrxThemeReloadHooks" ]
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
