{ pkgs, ... }: {
  aerospace = import ./aerospace/defaults.nix { inherit pkgs; };
  jankyborders = import ./jankyborders.nix { inherit pkgs; };
  # sketchybar = import ./sketchybar { inherit pkgs; };
}

