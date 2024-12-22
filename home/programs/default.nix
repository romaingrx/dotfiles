{ config, pkgs, ... }: {
  programs.git = import ./git.nix;
  programs.zsh = import ./zsh.nix { inherit config; };
  programs.ssh = import ./ssh.nix;
  programs.gpg = import ./gpg.nix;
  programs.alacritty = import ./alacritty.nix { inherit pkgs; };
}

