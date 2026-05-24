{
  pkgs,
  config,
  dotfilesPath,
  ...
}:
{

  home.packages = with pkgs; [
    neovim
    lua-language-server
    yaml-language-server
    vscode-langservers-extracted
    biome
    shfmt
    ripgrep
    typescript-language-server
  ];

  home.file.".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/nvim";
}
