{ ... }:
{
  imports = [
    ./options.nix
    ./packages
    ./programs
  ];
  home.stateVersion = "24.11"; # Please read the comment before changing.

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  nix = {
    settings = {
      trusted-substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
        "https://nixpkgs-wayland.cachix.org"
      ];
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
