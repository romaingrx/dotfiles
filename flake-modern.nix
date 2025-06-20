{
  description =
    "Modern Nix flake with clean abstractions and extensible architecture";

  inputs = {
    # Core inputs
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

    # Additional inputs
    nixvim = {
      url = "path:./third-party/nixvim";
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
    , fenix, pre-commit-hooks }:
    let
      # Import modern system builder
      mkModernSystem = import ./lib/mkModernSystem.nix {
        inherit inputs;
        lib = nixpkgs.lib;
      };

      # Import structured overlays
      overlaySet = import ./overlays/default.nix;
      overlays = [ overlaySet.patches overlaySet.customPackages ];

    in {
      # Development tools
      formatter = {
        aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-classic;
        x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-classic;
      };

      # Pre-commit hooks for code quality
      checks = nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ] (system:
        pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixfmt-classic.enable = true;
            deadnix.enable = true;
            statix.enable = true;
          };
        });

      # Development shells with modern tooling
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
                sops
                age
              ];
            };
          });

      # Modern system configurations
      nixosConfigurations = {
        "carl" = mkModernSystem {
          name = "carl";
          system = "x86_64-linux";
          darwin = false;
          users = [{
            name = "romaingrx";
            profiles = [ "developer" ];
            features = {
              development = true;
              productivity = true;
              security = true;
            };
          }];
          overlays = overlays;
        };
      };

      darwinConfigurations = {
        "goddard" = mkModernSystem {
          name = "goddard";
          system = "aarch64-darwin";
          darwin = true;
          users = [
            {
              name = "romaingrx";
              profiles = [ "power-user" ];
              features = {
                development = true;
                productivity = true;
                media = true;
                security = true;
              };
            }
            {
              name = "lcmd";
              profiles = [ "developer" ];
              features = {
                development = true;
                productivity = true;
              };
            }
          ];
          overlays = overlays;

          # Host-specific services
          services = {
            enable = true;
            sketchybar.enable = true;
            aerospace.enable = true;
            jankyborders.enable = true;
            mitmproxy.enable = true;
          };
        };
      };

      # Export modern libraries for reuse
      lib = {
        inherit mkModernSystem;
        mkService = import ./lib/mkService.nix;
        mkSecrets = import ./lib/mkSecrets.nix;
        mkHomeManager = import ./lib/mkHomeManager.nix;
      };
    };
}
