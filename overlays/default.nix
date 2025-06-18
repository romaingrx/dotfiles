# Default overlay collection
# This file provides a structured way to import all custom overlays
{
  # Custom packages overlay
  customPackages = import ./custom-packages.nix;

  # Patches and modifications overlay
  patches = import ./patches.nix;
}
