{ pkgs, ... }:
{
  imports = [
    ../../modules/common
    ../../modules/nvim.nix
    ./secrets.nix
    ./gpg.nix
    ./home-manager-nixos.nix
    ./home-manager-darwin.nix
    ./rust.nix
    ./tmux.nix
  ];

  # Enable the new configuration options
  myConfig = {
    common.enable = true;

    # User packages (Home Manager)
    packages = {
      enable = true;
      core.enable = true;
      development.enable = true;
      productivity.enable = true;
      extraPackages = with pkgs; [
        ollama
        tor
        mitmproxy
        brave
        tailscale
        claude-code
      ];
    };

    programs.enable = true;

    # System packages (environment.systemPackages)
    systemPackages = {
      enable = true;
      core.enable = true;
      development.enable = true;
    };
  };

  home.github.gpg = {
    key = "383E2222E1BEFDAD";
    email = "48758915+romaingrx@users.noreply.github.com";
  };
}
