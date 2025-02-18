{ config, pkgs, ... }: {
  # TODO romaingrx: Make this way cleaner
  programs = {
    git = import ./git.nix { inherit config; };
    zsh = import ./zsh.nix { inherit config pkgs; };
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
    ssh = import ./ssh.nix { inherit pkgs; };
    gpg = import ./gpg.nix;
    alacritty = import ./alacritty.nix { inherit pkgs; };
    tmux = import ./tmux.nix { inherit pkgs; };
    neovim = import ./neovim.nix { inherit pkgs; };
  };
}
