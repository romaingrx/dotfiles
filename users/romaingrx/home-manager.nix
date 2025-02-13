{ isLinux }:
{ pkgs, lib, ... }: {
  imports = [ ../../modules/core/common ]
    ++ lib.optional isLinux ./home-manager-nixos.nix;

  home.packages = with pkgs; [ ollama tor mitmproxy brave ];
}
