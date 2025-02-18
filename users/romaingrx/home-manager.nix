{ isLinux, ... }:
{ inputs, pkgs, lib, config, ... }: {
  imports = [ ../../modules/core/common ./secrets.nix ./gpg.nix ]
    ++ lib.optional isLinux ./home-manager-nixos.nix;

  home.packages = with pkgs; [ ollama tor mitmproxy brave ];
}
