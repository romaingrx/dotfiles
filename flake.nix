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
    romaingrx-nixvim = {
      url = "github:romaingrx/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      sops-nix,
      nixvim,
      romaingrx-nixvim,
      fenix,
    }:
    let
      # Import structured overlays
      overlaySet = import ./overlays/default.nix;

      # Convert overlay set to list of overlay functions
      overlays = [
        overlaySet.patches
        overlaySet.customPackages
      ];

      mkSystem = import ./lib/mkSystem.nix {
        inherit inputs;
        overlays = overlays;
        lib = nixpkgs.lib;
      };

    in
    {

      # Add formatter configuration
      formatter = {
        aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-rfc-style;
        x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
      };

      nixosConfigurations = {
        "carl" = (mkSystem "carl") {
          system = "x86_64-linux";
          users = [ "romaingrx" ];
        };
      };

      darwinConfigurations = {
        "goddard" = (mkSystem "goddard") {
          system = "aarch64-darwin";
          users = [
            "romaingrx"
            "lcmd"
          ];
          darwin = true;
        };
      };
    };
}
