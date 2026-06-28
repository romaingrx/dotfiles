{
  description = "Goddard nix-darwin system flake";

  inputs = {
    # Remote
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      pre-commit-hooks,
      ...
    }:
    let

      # Import structured overlays
      overlaySet = import ./overlays/default.nix;

      # Convert overlay set to list of overlay functions
      overlays = [
        overlaySet.patches
        overlaySet.customPackages
      ];

      dotfilesPath = ".dotfiles";

      mkSystem = import ./lib/mkSystem.nix {
        inherit inputs dotfilesPath overlays;
        inherit (nixpkgs) lib;
      };

    in
    {
      # Formatter configuration - matches CI workflow (.github/workflows/check.yml)
      formatter = {
        aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt;
        x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt;
      };

      # Checks - matches CI workflow (.github/workflows/check.yml)
      checks = nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ] (
        system:
        import ./checks {
          inherit pre-commit-hooks system;
          pkgs = nixpkgs.legacyPackages.${system};
          repoRoot = ./.;
        }
      );

      # Development shells with pre-commit
      devShells = nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ] (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            inherit (self.checks.${system}.pre-commit-check) shellHook;
            buildInputs = with pkgs; [
              nixfmt
              deadnix
              statix
              pre-commit
            ];
          };
        }
      );

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
          ];
          darwin = true;
        };
        "brobot" = (mkSystem "brobot") {
          system = "aarch64-darwin";
          users = [
            "romaingrx"
          ];
          darwin = true;
        };
      };
    };
}
