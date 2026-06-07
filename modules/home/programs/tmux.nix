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
  renderTheme = import ./tmux/theme.nix { inherit lib; };

  integrationConf = ".config/romaingrx/theme/tmux/integration.conf";

  generatedArtifacts = themeLib.generatedArtifacts "tmux" (appearanceTheme: {
    "flavor.conf" = renderTheme.flavor appearanceTheme;
  });

  # Contract integration sourced by tmux.conf via $ROMAINGRX_THEME_TMUX_CONF.
  integrationArtifact = {
    ${integrationConf}.text = renderTheme.integration {
      flavorConf = "${themeLib.currentAppDir "tmux"}/flavor.conf";
      themeGet = themeLib.themeBin "romaingrx-theme-get";
      themeSet = themeLib.themeBin "romaingrx-theme-set";
    };
  };

  # Re-theme a running tmux server after a theme apply. No-op when no server is
  # running or the Catppuccin plugin has not been installed yet, so it is safe
  # during Home Manager activation and on hosts without an active session.
  reloadHook = ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    tmux=${pkgs.tmux}/bin/tmux

    # No running server -> nothing to reload.
    "$tmux" list-sessions >/dev/null 2>&1 || exit 0

    # Pull the freshly-applied flavor into the running server.
    "$tmux" source-file -q "$ROMAINGRX_THEME_CURRENT/tmux/flavor.conf"

    # Re-apply the Catppuccin plugin so the new flavor takes effect, if present.
    catppuccin="$HOME/.tmux/plugins/tmux/catppuccin.tmux"
    if [ -x "$catppuccin" ]; then
      "$tmux" run-shell "$catppuccin"
    fi

    exit 0
  '';
in
{
  home = {
    packages = [ pkgs.tmux ];

    sessionVariables = lib.optionalAttrs cfg.enable {
      ROMAINGRX_THEME_TMUX_CONF = "${config.home.homeDirectory}/${integrationConf}";
    };

    file = {
      ".config/tmux".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/tmux";
    }
    // lib.optionalAttrs cfg.enable (
      generatedArtifacts // integrationArtifact // themeLib.reloadHook "60-tmux" reloadHook
    );
  };
}
