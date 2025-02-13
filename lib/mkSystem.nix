{ config, inputs, ... }:
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
  home-manager = if darwin then
    inputs.home-manager.darwinModules
  else
    inputs.home-manager.nixosModules;

  homeDirectory = "${if darwin then "/Users" else "/home"}/${user}";

in systemFunc {
  inherit system;
  modules = [
    hostConfig
    userOSConfig
    home-manager.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "bckp";
      home-manager.users.${user} = import userHMConfig;
    }
    {
      config._module.args = {
        homeDirectory = homeDirectory;
        inputs = inputs;
      };
    }
  ];
}
