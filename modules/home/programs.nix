{ pkgs, ... }:
{
  programs = {
    git = import ./programs/git.nix { };
    zsh = import ./programs/zsh.nix { inherit pkgs; };
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
    ssh = import ./programs/ssh.nix { inherit pkgs; };
    gpg = import ./programs/gpg.nix;
    alacritty = import ./programs/alacritty.nix { inherit pkgs; };
    tmux = import ./programs/tmux.nix { inherit pkgs; };
  };
}
