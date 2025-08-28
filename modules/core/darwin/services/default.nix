{ pkgs, ... }:
{
  sketchybar = import ./sketchybar { inherit pkgs; };
  aerospace = import ./aerospace { inherit pkgs; };
  jankyborders = import ./jankyborders.nix { inherit pkgs; };
  tailscale.enable = true;
}
