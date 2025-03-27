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
    let
      # Define overlays
      overlays = [
        # OpenSSH overlay
        (final: prev: {
          openssh = prev.openssh.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [ ./overlays/openssh.patch ];
            doCheck = false;
          });
        })
      ];

      mkSystem = import ./lib/mkSystem.nix {
        inherit inputs;
        overlays = overlays;
        lib = nixpkgs.lib;
      };
    in {
      nixosConfigurations = {
        "carl" = (mkSystem "carl") {
          system = "x86_64-linux";
          users = [ "romaingrx" ];
        };
      };

      darwinConfigurations = {
        "goddard" = (mkSystem "goddard") {
          system = "aarch64-darwin";
          users = [ "romaingrx" "lcmd" ];
          darwin = true;
        };
      };
    };
}
