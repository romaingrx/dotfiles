{
  pkgs,
  config,
  dotfilesPath,
  ...
}:
{
  home.packages = [ pkgs.tmux ];

  home.file.".config/tmux".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/tmux";
}
