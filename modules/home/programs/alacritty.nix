{
  pkgs,
  config,
  dotfilesPath,
  lib,
  ...
}:
let
  cfg = config.romaingrx.theme;
  theme = import ../../../lib/theme { };
  renderTheme = import ./alacritty/theme.nix { };
  alacrittyActiveTheme = "${config.home.homeDirectory}/.local/share/alacritty/active-theme.toml";
  themeLib = "${dotfilesPath}/config/bin/romaingrx-theme-lib";
  themeArtifact =
    appearance:
    lib.nameValuePair "${cfg.generatedRoot}/${appearance}/alacritty.toml" {
      text = renderTheme theme.appearances.${appearance};
    };
in
{
  romaingrx.theme.runtimeEnv = lib.mkIf cfg.enable {
    ROMAINGRX_THEME_ALACRITTY_ACTIVE_THEME = alacrittyActiveTheme;
  };

  home = {
    packages = [ pkgs.alacritty ];

    file = {
      ".config/alacritty".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/alacritty";
    }
    // lib.optionalAttrs cfg.enable (builtins.listToAttrs (map themeArtifact theme.appearanceNames));

    activation.romaingrxAlacrittyThemeBootstrap = lib.mkIf cfg.enable (
      lib.hm.dag.entryBetween [ "romaingrxThemeReloadHooks" ] [ "romaingrxThemeBootstrap" ] ''
        # shellcheck source=/dev/null
        source "${themeLib}"
        theme_bootstrap_alacritty
      ''
    );
  };
}
