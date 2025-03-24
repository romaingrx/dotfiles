{ isLinux, ... }:
{ inputs, pkgs, lib, config, ... }: {
  imports = [ ../../modules/core/common ./secrets.nix ./gpg.nix ./neovim.nix ]
    ++ lib.optional isLinux ./home-manager-nixos.nix;

  home.packages = with pkgs;
    [
      ollama
      tor
      mitmproxy
      brave
      just
      biome
      tailscale
      claude-code
      zoxide
      terraform
      awscli
    ] ++ lib.optional isLinux [ anytype ];

  # Set GitHub GPG configuration values
  home.github.gpg = {
    key = "EE706544613BE505";
    email = "48758915+romaingrx@users.noreply.github.com";
  };
}
