{
  description = "Goddard nix-darwin system flake";

  inputs = {
    # Remote
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, }:
    let
      mkSystem = import ./lib/mkSystem.nix { inherit inputs; };
    in {
      nixosConfigurations = {
        "carl" = (mkSystem "carl") {
          system = "x86_64-linux";
          user = "romaingrx";
        };
      };

      darwinConfigurations = {
        # Original goddard configuration
        "romaingrx@goddard" = (mkSystem "goddard") {
          system = "aarch64-darwin";
          user = "romaingrx";
          darwin = true;
        };

        # Work configuration
        "lcmd@goddard" = (mkSystem "goddard") {
          system = "aarch64-darwin";
          user = "lcmd";
          darwin = true;
        };
      };
    };
}
