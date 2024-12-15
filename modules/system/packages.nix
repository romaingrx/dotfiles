{pkgs, ...}: {
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    neovim
    tmux
    nixpkgs-fmt
    git
    gnupg
    gh
    # bitwarden-cli

    # Apps
    ## Default
    obsidian
    signal-desktop
    # spotify

    ## MacOS only
    raycast
    alacritty
  ];

  environment.shellAliases = {
    nixvim = "nix run ~/.config/nix/nixvim#default";
  };
} 