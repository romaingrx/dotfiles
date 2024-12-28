{pkgs, ...}: {
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    neovim
    tmux
    nixpkgs-fmt
    nix-prefetch-git
    git
    gnupg
    gh
  ];

  environment.shellAliases = {
    nixvim = "nix run ~/.config/nix/nixvim#default";
  };
} 