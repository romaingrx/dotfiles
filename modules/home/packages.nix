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
      nixfmt-rfc-style
      bat
      jq
      yq
      nix-prefetch-git
      gh

      # Development
      lazygit
      git-lfs
      pre-commit
      uv
      pnpm
      nodejs
      awscli2
      zoxide
      kubectl
      k9s

      # Productivity
      alacritty
      obsidian
      slack
    ]
    ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [ raycast ];
}
