{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    nixpkgs-fmt
    nix-prefetch-git
    git
    gnupg
    gh
    raycast
  ];
}
