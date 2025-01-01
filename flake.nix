{
  description = "Goddard nix-darwin system flake";

  inputs = {
    # Remote
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # Local
    nixvim-config.url = "./nixvim";
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, nix-homebrew, home-manager, nixvim-config }:
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#goddard
    darwinConfigurations."goddard" = nix-darwin.lib.darwinSystem {
      modules = [
        ./hosts/goddard
        nixvim-config.darwinModules.default
        home-manager.darwinModules.home-manager {
          users.users = {
            romaingrx = {
              name = "romaingrx";
              home = "/Users/romaingrx";
            };
            lcmd = {
              name = "lcmd";
              home = "/Users/lcmd";
            };
          };
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "bckp";
            users = {
              romaingrx = import ./profiles/personal;
              lcmd = import ./profiles/work;
            };
          };
        }
        nix-homebrew.darwinModules.nix-homebrew {
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            user = "romaingrx"; # Keep primary user as homebrew manager
          };
        }
      ];
    };
  };
}
