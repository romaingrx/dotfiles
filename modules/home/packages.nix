{ pkgs, ... }:
{
  home.packages =
    with pkgs;
    [
      # Core
      curl
      wget
      sops
      just
      nil
      nixfmt
      bat
      jq
      yq
      nix-prefetch-git
      gh
      _1password-cli

      # Development
      lazygit
      git-lfs
      pre-commit
      uv
      pnpm
      nodejs
      awscli2
      kubectl
      k9s

      # Productivity
      obsidian
      slack
    ]
    ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
      raycast
      mactop
      watch
      mas
    ];
}
