{
  programs.git = import ./git.nix;
  programs.zsh = import ./zsh.nix;
  programs.bash.enable = false;
}