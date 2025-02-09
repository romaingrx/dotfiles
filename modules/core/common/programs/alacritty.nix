{ pkgs, ... }: {
  enable = true;
  package = pkgs.alacritty;
  settings = { font = { normal = { family = "FiraCode Nerd Font"; }; }; };
}
