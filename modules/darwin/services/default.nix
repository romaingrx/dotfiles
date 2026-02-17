{ pkgs, ... }:
{
  imports = [ ./sketchybar ];
  services = {
    aerospace = import ./aerospace { inherit pkgs; };
    jankyborders = import ./jankyborders.nix { inherit pkgs; };
  };
}
