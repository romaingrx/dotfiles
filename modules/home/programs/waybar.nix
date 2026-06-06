{
  config,
  dotfilesPath,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.romaingrx.theme;
  theme = import ../../../lib/theme { };
  renderTheme = import ./waybar/theme.nix { inherit lib; };
  currentWaybarRoot = "${config.home.homeDirectory}/${cfg.runtimeRoot}/current/waybar";
  legacyWaybarConfig = "${config.home.homeDirectory}/.config/waybar";
  legacyWaybarTargets = [
    "${dotfilesPath}/config/waybar"
    "${config.home.homeDirectory}/${dotfilesPath}/config/waybar"
  ];
  expectedLegacyTargets = lib.concatStringsSep " " (map lib.escapeShellArg legacyWaybarTargets);
  themeArtifacts =
    appearance:
    let
      appearanceTheme = theme.appearances.${appearance};
      generatedRoot = "${cfg.generatedRoot}/${appearance}/waybar";
    in
    [
      (lib.nameValuePair "${generatedRoot}/config.jsonc" {
        text = renderTheme.config appearanceTheme;
      })
      (lib.nameValuePair "${generatedRoot}/style.css" {
        text = renderTheme.style appearanceTheme;
      })
    ];
  generatedArtifacts = builtins.listToAttrs (lib.flatten (map themeArtifacts theme.appearanceNames));
in
{
  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home.activation.romaingrxWaybarLegacyConfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      waybar_config=${lib.escapeShellArg legacyWaybarConfig}
      if [ -L "$waybar_config" ]; then
        current_target="$(readlink "$waybar_config")"
        for expected_target in ${expectedLegacyTargets}; do
          if [ "$current_target" = "$expected_target" ]; then
            rm "$waybar_config"
            break
          fi
        done
      fi
    '';

    home.file = generatedArtifacts // {
      ".config/waybar/config.jsonc".text =
        builtins.toJSON {
          include = [ "${currentWaybarRoot}/config.jsonc" ];
        }
        + "\n";

      ".config/waybar/style.css".text = ''
        @import url("file://${currentWaybarRoot}/style.css");
      '';
    };
  };
}
