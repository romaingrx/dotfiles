{
  pkgs,
  config,
  dotfilesPath,
  ...
}:
{
  home.packages = [ pkgs.alacritty ];

  home.file.".config/alacritty".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/alacritty";
}
