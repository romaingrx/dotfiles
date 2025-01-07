{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    nixvim.url = "github:nix-community/nixvim";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = { nixvim, ... } @ inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
      
      flake = {
        darwinModules.default = { pkgs, ... }: {
          environment.systemPackages = [
            (nixvim.legacyPackages.${pkgs.system}.makeNixvimWithModule {
              inherit pkgs;
              module = import ./config;
            })
          ];
        };
      };

      perSystem = { pkgs, ... }: {
        packages.default = nixvim.legacyPackages.${pkgs.system}.makeNixvimWithModule {
          inherit pkgs;
          module = import ./config;
        };
      };
    };
}