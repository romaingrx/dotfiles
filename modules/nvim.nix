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

  programs.neovim = {
    enable = true;
    withPython3 = true;
    withRuby = false;
    sideloadInitLua = true;
    extraPackages = [ pkgs.tree-sitter ];
    extraWrapperArgs = [
      "--set-default"
      "CC"
      "${pkgs.stdenv.cc}/bin/cc"
    ];
  };

  home.packages = with pkgs; [
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
