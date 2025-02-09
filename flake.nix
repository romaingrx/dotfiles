{
  description = "Goddard nix-darwin system flake";

  inputs = {
    # Remote
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    # nix-darwin.url = "github:dlubawy/nix-darwin/develop";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, nix-homebrew, home-manager }:
    let
      # Define common modules that will be shared across configurations
      commonModules = [ home-manager.darwinModules.home-manager ];

      # Define different machine configurations
      mkDarwinConfig = { host, user, homeDirectory ? "/Users/${user}" }:
        nix-darwin.lib.darwinSystem {
          inherit inputs;
          modules = [
            ({ config, pkgs, ... }:
              import ./hosts/darwin/${host} {
                inherit config pkgs homeDirectory;
              })
            {
              users.users.${user} = {
                name = user;
                home = homeDirectory;
                createHome = true;
              };
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "bckp";
                users.${user} = { config, pkgs, ... }:
                  import ./modules/profiles/${user} { inherit config pkgs; };
              };
              nix-homebrew = {
                enable = true;
                enableRosetta = true;
                user = user;
              };
            }
            nix-homebrew.darwinModules.nix-homebrew
          ] ++ commonModules;
        };
    in {
      darwinConfigurations = {
        # Original goddard configuration
        "romaingrx@goddard" = mkDarwinConfig {
          host = "goddard";
          user = "romaingrx";
          homeDirectory = "/Users/romaingrx";
        };

        # Work configuration
        "lcmd@goddard" = mkDarwinConfig {
          host = "goddard";
          user = "lcmd";
          homeDirectory = "/Users/lcmd";
        };
      };
    };
}
