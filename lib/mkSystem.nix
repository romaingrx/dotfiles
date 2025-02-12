{ config, inputs, ... }:
name:
{ system, user, darwin ? false, ... }:
let
  hostConfig = ../hosts/${if darwin then "darwin" else "nixos"}/${name};

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
    home-manager.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "bckp";
      home-manager.users.${user} = import ../users/${user};
      users.users.${user} = {
        home = homeDirectory;
        createHome = true;
        name = user;
      };
    }
    {
      config._module.args = {
        homeDirectory = homeDirectory;
        inputs = inputs;
      };
    }
  ];
}
