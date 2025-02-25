{ inputs, overlays }:
name:
{ system, user, darwin ? false, ... }:
let
  hostConfig = ../hosts/${if darwin then "darwin" else "nixos"}/${name};
  userOSConfig = ../users/${user}/${if darwin then "darwin" else "nixos"}.nix;
  userHMConfig = ../users/${user}/home-manager.nix;

  # NixOS vs nix-darwin functions
  systemFunc = if darwin then
    inputs.nix-darwin.lib.darwinSystem
  else
    inputs.nixpkgs.lib.nixosSystem;

  sops-nix = if darwin then
    inputs.sops-nix.darwinModules
  else
    inputs.sops-nix.nixosModules;

  home-manager = if darwin then
    inputs.home-manager.darwinModules
  else
    inputs.home-manager.nixosModules;

  homeDirectory = "${if darwin then "/Users" else "/home"}/${user}";

in systemFunc {
  inherit system;
  modules = [
    {
      config._module.args = {
        homeDirectory = homeDirectory;
        inputs = inputs;
      };
    }
    # Allow unfree packages globally
    {
      nixpkgs.config.allowUnfree = true;
      nixpkgs.overlays = overlays;
    }

    # Sops
    sops-nix.sops
    hostConfig
    userOSConfig
    home-manager.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "bckp";
      home-manager.users.${user} = import userHMConfig { isLinux = !darwin; };
      home-manager.sharedModules = [
        inputs.sops-nix.homeManagerModules.sops
        inputs.nixvim.homeManagerModules.nixvim
      ];
    }
  ];
}
