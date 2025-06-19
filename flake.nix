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
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, sops-nix, nixvim
    , romaingrx-nixvim, fenix, pre-commit-hooks, }:
    let

      # Import structured overlays
      overlaySet = import ./overlays/default.nix;

      # Convert overlay set to list of overlay functions
      overlays = [ overlaySet.patches overlaySet.customPackages ];

      mkSystem = import ./lib/mkSystem.nix {
        inherit inputs;
        overlays = overlays;
        lib = nixpkgs.lib;
      };

    in {

      # Formatter configuration - matches CI workflow (.github/workflows/nixfmt.yml)
      formatter = {
        aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-classic;
        x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-classic;
      };

      # Pre-commit hooks
      checks = nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ] (system:
        pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixfmt-classic = {
              enable = true;
              package = nixpkgs.legacyPackages.${system}.nixfmt-classic;
            };
            deadnix.enable = true;
            statix.enable = true;
          };
        });

      # Development shells with pre-commit
      devShells = nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ]
        (system:
          let pkgs = nixpkgs.legacyPackages.${system};
          in {
            default = pkgs.mkShell {
              inherit (self.checks.${system}) shellHook;
              buildInputs = with pkgs; [
                nixfmt-classic
                deadnix
                statix
                pre-commit
              ];
            };
          });

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
