{ pkgs, ... }:
{
  services.sketchybar = {
    enable = true;
    package = pkgs.sketchybar;
    config = "~/.config/sketchybar/sketchybarrc";
    extraPackages = with pkgs; [
      lua5_4
      jq
      tree
    ];
  };
}
