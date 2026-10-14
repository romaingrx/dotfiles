{
  pkgs,
  config,
  dotfilesPath,
  ...
}:
let
  theme = import ../lib/theme;
in
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

  # Read by config/nvim/lua/plugins/theme.lua.
  xdg.configFile."theme/nvim.lua".text = ''
    return { flavour = "${theme.flavor}" }
  '';
}
