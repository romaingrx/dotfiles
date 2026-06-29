{ pkgs, ... }:
{
  home.packages =
    with pkgs;
    [
      # Core
      git
      curl
      wget
      gnupg
      sops
      just
      biome
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
      google-cloud-sdk
      zoxide
      kubectl
      k9s

      # Productivity
      alacritty
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
