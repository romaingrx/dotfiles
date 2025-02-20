{
  description = "Goddard nix-darwin system flake";

  inputs = {
    # Remote
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self, nixpkgs, nix-darwin, home-manager, sops-nix, nixvim }:
    let mkSystem = import ./lib/mkSystem.nix { inherit inputs; };
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
