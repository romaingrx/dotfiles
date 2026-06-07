{
  config,
  dotfilesPath,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.romaingrx.theme;
  themeLib = import ../theme/lib.nix { inherit config dotfilesPath lib; };
  renderTheme = import ./borders/theme.nix { inherit lib; };
  generatedArtifacts = themeLib.generatedArtifacts "borders" (appearanceTheme: {
    "colors.sh" = renderTheme.colors appearanceTheme;
  });
  # Re-color a running jankyborders instance after a theme apply. Guarded on the
  # launchd service so it is a no-op when borders is not managed/running, and
  # consumes the active appearance's colors from the runtime `current` tree.
  reloadHook = ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    /bin/launchctl print "gui/$UID/org.nixos.jankyborders" >/dev/null 2>&1 || exit 0

    # shellcheck source=/dev/null
    source "$ROMAINGRX_THEME_CURRENT/borders/colors.sh"

    exec ${pkgs.jankyborders}/bin/borders \
      active_color="$BORDER_ACTIVE_COLOR" \
      inactive_color="$BORDER_INACTIVE_COLOR"
  '';
in
{
  config = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    home.file = generatedArtifacts // themeLib.reloadHook "70-borders" reloadHook;
  };
}
