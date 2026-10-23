{ pkgs, inputs, ... }:
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
      inputs.nixpkgs-master.legacyPackages.${pkgs.stdenv.hostPlatform.system}.uv
      pnpm
      nodejs
      awscli2
      kubectl
      k9s
    ]
    ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
      mactop
      watch
      mas
    ];
}
