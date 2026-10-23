{
  description = "Goddard nix-darwin system flake";

  inputs = {
    # Remote inputs track the unstable / master channels. Always update them
    # together (`nix flake update`) — never bump one alone, or nix-darwin's
    # release check fails against a skewed nixpkgs. Renovate's
    # lockFileMaintenance performs this lockstep refresh automatically.
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Temporary: uv >= 0.13.4 drops the compromised eMudhra emSign ECC G3 root,
    # and unstable still ships 0.13.1. Drop this input (and its use in
    # modules/home/packages.nix) once unstable catches up.
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
      # nix-homebrew pins the brew binary, but cask definitions are fetched live
      # from the formulae.brew.sh API, which always serves definitions generated
      # by the latest brew. Left alone, brew tracks nix-homebrew's release
      # cadence while the definitions track Homebrew's, and a new cask stanza on
      # one side breaks `brew bundle` on the other. Own the pin here so both
      # sides follow Homebrew and Renovate's lockFileMaintenance moves them
      # together.
      inputs.brew-src.follows = "brew-src";
    };
    brew-src = {
      url = "github:Homebrew/brew";
      flake = false;
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Review-first terminal diff viewer; exposes a package + Home Manager module
    # and is wired up as git's diff pager in modules/home/programs/hunk.nix.
    hunk = {
      url = "github:modem-dev/hunk";
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
      inherit (nixpkgs) lib;
      forAllSystems =
        f: lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ] (s: f nixpkgs.legacyPackages.${s});

      mkSystem = import ./lib/mkSystem.nix {
        inherit inputs lib;
        dotfilesPath = ".dotfiles";
      };
    in
    {
      formatter = forAllSystems (pkgs: pkgs.nixfmt);

      checks = forAllSystems (
        pkgs:
        import ./checks {
          inherit pkgs pre-commit-hooks;
          inherit (pkgs.stdenv.hostPlatform) system;
          repoRoot = ./.;
        }
      );

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          inherit (self.checks.${pkgs.stdenv.hostPlatform.system}.pre-commit-check) shellHook;
          buildInputs = with pkgs; [
            nixfmt
            deadnix
            # statix's own tests fail to build on current nixpkgs; skip them
            # (the linter works). Drop the override once fixed upstream.
            (statix.overrideAttrs (_: {
              doCheck = false;
            }))
            pre-commit
          ];
        };
      });

      # Home-manager activation for dev containers; built impurely by
      # devcontainer.sh for whichever user the container runs as.
      legacyPackages = forAllSystems (pkgs: {
        devcontainer =
          (inputs.home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            extraSpecialArgs.dotfilesPath = builtins.getEnv "DOTFILES";
            modules = [
              ./hosts/devcontainer/home.nix
              {
                home.username = builtins.getEnv "USER";
                home.homeDirectory = builtins.getEnv "HOME";
              }
            ];
          }).activationPackage;
      });

      nixosConfigurations.carl = mkSystem "carl" {
        system = "x86_64-linux";
        user = "romaingrx";
      };

      darwinConfigurations = lib.genAttrs [ "goddard" "brobot" ] (
        name:
        mkSystem name {
          system = "aarch64-darwin";
          user = "romaingrx";
        }
      );
    };
}
