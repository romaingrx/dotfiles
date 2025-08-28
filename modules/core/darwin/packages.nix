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

  environment.shellAliases = {
    nixvim = "nix run ~/.config/nix/nixvim#default";
  };
}
