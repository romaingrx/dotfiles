{pkgs, ...}: {
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    neovim
    tmux
    nixpkgs-fmt
    git
    gnupg
    gh

    # Apps
    ## Default
    obsidian
    signal-desktop

    ## MacOS only
    raycast
    alacritty
  ];

  environment.shellAliases = {
    nixvim = "nix run ~/.config/nix/nixvim#default";
  };
} 