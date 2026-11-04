# Builds a NixOS or nix-darwin system for one host and its single user.
# `identity` is "personal" (default) or "work": a work host gets no personal
# secrets (sops age key, GPG key, personal GitHub SSH key) and a work git
# identity; see users/<user>/home-manager.nix.
{
  inputs,
  lib,
  dotfilesPath,
}:
name:
{
  system,
  user,
  identity ? "personal",
}:
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
  specialArgs = { inherit inputs homeDirectory identity; };
  modules = [
    hostDir
    ../users/${user}/${systemType}.nix
    ../modules/nix.nix
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
          inherit inputs identity;
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
