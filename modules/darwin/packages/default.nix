{pkgs, ...}: {
  sbarLua = pkgs.callPackage ./sbarLua.nix {};
} 