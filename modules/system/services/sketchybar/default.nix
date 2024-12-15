{pkgs, ...}: {
  enable = true;
  package = pkgs.sketchybar;
  config = builtins.readFile ./sketchybarrc;
}