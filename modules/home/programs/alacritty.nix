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
  themeArtifact =
    appearance:
    lib.nameValuePair "${cfg.generatedRoot}/${appearance}/alacritty.toml" {
      text = renderTheme theme.appearances.${appearance};
    };
in
{
  home = {
    packages = [ pkgs.alacritty ];

    file = {
      ".config/alacritty".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/alacritty";
    }
    // lib.optionalAttrs cfg.enable (builtins.listToAttrs (map themeArtifact theme.appearanceNames));

    activation.romaingrxAlacrittyThemeBootstrap = lib.mkIf cfg.enable (
      lib.hm.dag.entryAfter [ "romaingrxThemeBootstrap" ] ''
        active_dir="${config.home.homeDirectory}/.local/share/alacritty"
        active_theme="$active_dir/active-theme.toml"
        current_theme="${config.home.homeDirectory}/${cfg.runtimeRoot}/current/alacritty.toml"

        mkdir -p "$active_dir"
        tmp_link="$active_dir/.active-theme.toml.tmp.$$"
        rm -f "$tmp_link"
        ln -s "$current_theme" "$tmp_link"

        if [ -e "$active_theme" ] && [ ! -L "$active_theme" ]; then
          echo "Refusing to replace non-symlink Alacritty theme: $active_theme" >&2
          rm -f "$tmp_link"
          exit 1
        fi

        rm -f "$active_theme"
        mv "$tmp_link" "$active_theme"
      ''
    );
  };
}
