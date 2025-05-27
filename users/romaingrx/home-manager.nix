{ pkgs, inputs, ... }: {
  imports = [
    ../../modules/core/common
    ./secrets.nix
    ./gpg.nix
    ./home-manager-nixos.nix
    ./rust.nix
  ];

  home.packages = with pkgs; [
    inputs.romaingrx-nixvim.packages.${system}.default
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
    openjdk
  ];
  # Set GitHub GPG configuration values
  home.github.gpg = {
    key = "EE706544613BE505";
    email = "48758915+romaingrx@users.noreply.github.com";
  };
}
