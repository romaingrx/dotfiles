{
  pkgs,
  config,
  dotfilesPath,
  ...
}:
let
  theme = import ../lib/theme;
  tree-sitter = pkgs.writeShellScriptBin "tree-sitter" ''
    CC="''${CC:-${pkgs.stdenv.cc}/bin/cc}" exec ${pkgs.tree-sitter}/bin/tree-sitter "$@"
  '';
in
{

  programs.neovim = {
    enable = true;
    withPython3 = true;
    withRuby = false;
    sideloadInitLua = true;
    extraPackages = with pkgs; [
      tree-sitter
      stdenv.cc
      curl
      gnutar
      fd
      lua-language-server
      stylua
      ty
      basedpyright
      ruff
      rust-analyzer
      vtsls
      vscode-langservers-extracted
      yaml-language-server
      biome
      oxlint
      oxfmt
      shfmt
      nil
      nixfmt
      statix
    ];
  };

  home.packages = [ pkgs.ripgrep ];

  home.file.".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/nvim";

  # Read by config/nvim/lua/plugins/theme.lua.
  xdg.configFile."theme/nvim.lua".text = ''
    return { flavour = "${theme.flavor}" }
  '';
}
