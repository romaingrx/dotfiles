{
  imports = [
    ./packages.nix
    ./programs.nix
    ./tl.nix
  ];

  home = {
    stateVersion = "24.11";

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };

  programs.home-manager.enable = true;
}
