# Function that creates a NixOS or Darwin system configuration
{
  inputs,
  overlays,
  lib,
  dotfilesPath,
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

  # Optional per-host home-manager overrides, auto-imported only when present.
  # Mirrors hostConfig (the per-host system module) for the home-manager layer.
  hostHomeModule = ../hosts/${systemType}/${name}/home.nix;
  hasHostHome = builtins.pathExists hostHomeModule;

  # Home Manager configurations, keyed by user: each user's shared home config
  # plus the optional per-host home.nix when it exists.
  usersHMConfig = lib.genAttrs users (user: {
    imports = [
      (import ../users/${user}/home-manager.nix { inherit inputs pkgs; })
    ]
    ++ lib.optional hasHostHome hostHomeModule;
  });

  # User-specific configurations
  # TODO: Remove once https://github.com/LnL7/nix-darwin/pull/1341 is merged
  primaryUser = builtins.head users;
  homeDirectory = "${if darwin then "/Users" else "/home"}/${primaryUser}";
  absoluteDotfilesPath = "${homeDirectory}/${dotfilesPath}";

in
# The shared modules assume a single primary user per host (homeDirectory above
# collapses to the first user). Fail loudly rather than silently misconfigure a
# second user.
assert lib.assertMsg (builtins.length users == 1)
  "mkSystem: host '${name}' declares ${toString (builtins.length users)} users, but a host currently supports exactly one.";
systemFunc {
  modules = [
    # Basic system configuration
    {
      nixpkgs = {
        # Single source of truth for the platform: the flake `system` arg drives
        # both the `pkgs` built above and the system module set here.
        hostPlatform = system;
        config = {
          allowUnfree = true;
        };
        inherit overlays;
      };
    }

    # Module arguments
    {
      config._module.args = {
        inherit homeDirectory inputs;
        pkgs-stable = import inputs.nixpkgs-stable {
          inherit system;
          config.allowUnfree = true;
        };
      };
    }

    # Core system configuration
    hostConfig

    # Cachix binary cache
    ../modules/cachix.nix

    # Fonts installed from the theme contract (shared by NixOS and darwin)
    ../modules/fonts.nix

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
        ];
        extraSpecialArgs = {
          inherit inputs pkgs;
          dotfilesPath = absoluteDotfilesPath;
        };
      };
    }

    # Sops configuration
    (if darwin then inputs.sops-nix.darwinModules.sops else inputs.sops-nix.nixosModules.sops)
  ]
  # User OS configurations (reversed to maintain priority)
  # ++ lib.lists.reverseList usersOSConfig;
  ++ usersOSConfig
  # nix-homebrew installs and manages Homebrew itself (darwin only).
  ++ lib.optional darwin inputs.nix-homebrew.darwinModules.nix-homebrew;
}
