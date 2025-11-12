{ pkgs, config, ... }:
{

  home.packages = with pkgs; [
    neovim
    lua-language-server
    yaml-language-server
    vscode-langservers-extracted
    biome
    shfmt
    ripgrep
    nodePackages_latest.typescript-language-server
  ];

  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/config/nvim";
  # stylix.targets.neovim.enable = false;
}
