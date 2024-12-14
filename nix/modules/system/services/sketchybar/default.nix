{pkgs, ...}: {
  enable = false;
  package = pkgs.sketchybar;
  config = builtins.readFile ./sketchybarrc;
}