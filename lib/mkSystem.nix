{ inputs, overlays, lib }:
name:
{ system, users, darwin ? false, ... }:
let
  hostConfig = ../hosts/${if darwin then "darwin" else "nixos"}/${name};
  usersOSConfig = builtins.map
    (user: ../users/${user}/${if darwin then "darwin" else "nixos"}.nix) users;
  usersHMConfigList =
    builtins.map (user: ../users/${user}/home-manager.nix) users;
  usersHMConfig = builtins.listToAttrs (lib.lists.imap0 (i: config: {
    name = builtins.elemAt users i;
    value = config;
  }) usersHMConfigList);

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

  # This is needed for darwin systems as nix-darwin does not support multiple users as of now.
  # We'll need to remove this once https://github.com/LnL7/nix-darwin/pull/1341 is merged.
  primaryUser = builtins.head users;
  homeDirectory = "${if darwin then "/Users" else "/home"}/${primaryUser}";

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
    home-manager.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "bckp";
      # Turn the list of users into a set of users with names as keys
      home-manager.users = usersHMConfig;
      home-manager.sharedModules = [
        inputs.sops-nix.homeManagerModules.sops
        inputs.nixvim.homeManagerModules.nixvim
      ];
    }
  # Reverse so that the first user overrides anything, also need to removes it once the PR is merged.
  ] ++ lib.lists.reverseList usersOSConfig;
}
