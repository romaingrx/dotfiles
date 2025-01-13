{pkgs, ...}: 
let
  customPackages = import ./packages { inherit pkgs; };
in
{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    nixpkgs-fmt
    nix-prefetch-git
    git
    gnupg
    gh
    lua
    jq
    tree
    customPackages.sbarLua
  ];
} 