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

      # Pre-commit hooks
      checks = nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ] (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          theme = import ./lib/theme { };
          renderAlacrittyTheme = import ./modules/home/programs/alacritty/theme.nix { };
        in
        {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixfmt-rfc-style = {
                enable = true;
                package = pkgs.nixfmt;
                excludes = [ "third-party/" ];
              };
              deadnix.enable = true;
              statix.enable = true;
            };
          };

          theme-alacritty-golden =
            pkgs.runCommand "theme-alacritty-golden" { nativeBuildInputs = [ pkgs.diffutils ]; }
              ''
                diff -u \
                  ${./config/alacritty/themes/catppuccin-mocha.toml} \
                  ${pkgs.writeText "generated-catppuccin-mocha.toml" (renderAlacrittyTheme theme.appearances.dark)}
                diff -u \
                  ${./config/alacritty/themes/catppuccin-latte.toml} \
                  ${pkgs.writeText "generated-catppuccin-latte.toml" (renderAlacrittyTheme theme.appearances.light)}
                touch "$out"
              '';

          theme-runtime-contract =
            pkgs.runCommand "theme-runtime-contract"
              {
                nativeBuildInputs = [
                  pkgs.bash
                  pkgs.coreutils
                  pkgs.gnugrep
                ];
              }
              ''
                THEME_LIB=${./config/bin/romaingrx-theme-lib} \
                  ${pkgs.bash}/bin/bash ${./tests/theme-lib.sh}
                touch "$out"
              '';
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
      };
    };
}
