# Function that creates a NixOS or Darwin system configuration
{
  inputs,
  overlays,
  lib,
}:
name:
{
  system,
  users,
  darwin ? false,
  ...
}:
let
  # Basic system configuration with unfree packages allowed
  pkgs = import inputs.nixpkgs {
    inherit system overlays;
    config = {
      allowUnfree = true;
    };
  };

  # System-specific configurations
  systemType = if darwin then "darwin" else "nixos";
  systemFunc = if darwin then inputs.nix-darwin.lib.darwinSystem else inputs.nixpkgs.lib.nixosSystem;

  # Path configurations
  hostConfig = ../hosts/${systemType}/${name};
  usersOSConfig = builtins.map (user: ../users/${user}/${systemType}.nix) users;

  # Home Manager configurations
  usersHMConfigList = builtins.map (
    user: import ../users/${user}/home-manager.nix { inherit inputs pkgs; }
  ) users;
  usersHMConfig = builtins.listToAttrs (
    lib.lists.imap0 (i: config: {
      name = builtins.elemAt users i;
      value = config;
    }) usersHMConfigList
  );

  # User-specific configurations
  # TODO: Remove once https://github.com/LnL7/nix-darwin/pull/1341 is merged
  primaryUser = builtins.head users;
  homeDirectory = "${if darwin then "/Users" else "/home"}/${primaryUser}";

in
systemFunc {
  inherit system;
  modules = [
    # Basic system configuration
    {
      nixpkgs = {
        config = {
          allowUnfree = true;
        };
        inherit overlays;
      };
    }

    # Module arguments
    {
      config._module.args = { inherit homeDirectory inputs; };
    }

    # Core system configuration
    hostConfig

    # Cachix binary cache
    ../modules/cachix.nix

    # Home Manager configuration
    (
      if darwin then
        inputs.home-manager.darwinModules.home-manager
      else
        inputs.home-manager.nixosModules.home-manager
    )
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "bckp";
        users = usersHMConfig;
        sharedModules = [
          inputs.sops-nix.homeManagerModules.sops
          inputs.nixvim.homeManagerModules.nixvim
        ];
        extraSpecialArgs = { inherit inputs pkgs; };
      };
    }

    # Sops configuration
    (if darwin then inputs.sops-nix.darwinModules.sops else inputs.sops-nix.nixosModules.sops)
  ]
  # User OS configurations (reversed to maintain priority)
  # ++ lib.lists.reverseList usersOSConfig;
  ++ usersOSConfig;
}
