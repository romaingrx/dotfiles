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
      url = "path:./modules/nixvim";
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

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      sops-nix,
      nixvim,
      fenix,
      pre-commit-hooks,
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

      # Formatter configuration - matches CI workflow (.github/workflows/nixfmt.yml)
      formatter = {
        aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-rfc-style;
        x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
      };

      # Pre-commit hooks
      checks = nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ] (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixfmt-rfc-style = {
                enable = true;
                package = pkgs.nixfmt-rfc-style;
                excludes = [ "third-party/" ];
              };
              # deadnix.enable = true;  # Temporarily disabled
              # statix.enable = true;  # Temporarily disabled to allow build
            };
          };
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
              nixfmt-rfc-style
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
            "lcmd"
          ];
          darwin = true;
        };
      };
    };
}
