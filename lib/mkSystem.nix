# Builds a NixOS or nix-darwin system for one host and its single user.
{
  inputs,
  lib,
  dotfilesPath,
}:
name:
{ system, user }:
let
  darwin = lib.hasSuffix "darwin" system;
  systemType = if darwin then "darwin" else "nixos";
  systemFunc = if darwin then inputs.nix-darwin.lib.darwinSystem else inputs.nixpkgs.lib.nixosSystem;
  modulesFor = if darwin then "darwinModules" else "nixosModules";

  hostDir = ../hosts/${systemType}/${name};
  hostHome = hostDir + "/home.nix";
  homeDirectory = "${if darwin then "/Users" else "/home"}/${user}";
in
systemFunc {
  specialArgs = {
    inherit inputs homeDirectory;
    pkgs-stable = import inputs.nixpkgs-stable {
      inherit system;
      config.allowUnfree = true;
    };
  };
  modules = [
    hostDir
    ../users/${user}/${systemType}.nix
    ../modules/cachix.nix
    ../modules/fonts.nix
    inputs.home-manager.${modulesFor}.home-manager
    inputs.sops-nix.${modulesFor}.sops
    {
      nixpkgs = {
        hostPlatform = system;
        config.allowUnfree = true;
      };

      users.users.${user}.home = homeDirectory;

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "bckp";
        sharedModules = [ inputs.sops-nix.homeManagerModules.sops ];
        extraSpecialArgs = {
          inherit inputs;
          dotfilesPath = "${homeDirectory}/${dotfilesPath}";
        };
        users.${user}.imports = [
          ../users/${user}/home-manager.nix
        ]
        ++ lib.optional (builtins.pathExists hostHome) hostHome;
      };
    }
  ]
  ++ lib.optionals darwin [
    inputs.nix-homebrew.darwinModules.nix-homebrew
    { system.primaryUser = user; }
  ];
}
