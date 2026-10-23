{ pkgs, inputs, ... }:
let
  # Tools we want ahead of unstable; see the nixpkgs-master input in flake.nix.
  master = inputs.nixpkgs-master.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
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
      master.gh
      _1password-cli

      # Development
      lazygit
      git-lfs
      pre-commit
      master.uv
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
