{
  pkgs,
  config,
  dotfilesPath,
  ...
}:
let
  theme = import ../../../lib/theme;
in
{
  home = {
    packages = [ pkgs.alacritty ];
    file.".config/alacritty".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/alacritty";
  };

  # Imported by config/alacritty/alacritty.toml: the official Catppuccin port
  # for the configured flavor, plus the theme font.
  xdg.configFile."theme/alacritty.toml".text = ''
    ${builtins.readFile ../../../config/alacritty/themes/catppuccin-${theme.flavor}.toml}
    [font.normal]
    family = "${theme.font.family}"
  '';
}
