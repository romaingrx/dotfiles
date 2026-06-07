{
  config,
  dotfilesPath,
  lib,
  ...
}:
let
  themeLib = import ./theme/lib.nix { inherit config dotfilesPath lib; };
in
{
  imports = [
    ./packages.nix
    ./programs.nix
    ./theme
  ];

  home = {
    stateVersion = "24.11";

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    file = themeLib.themeCommandFiles;
  };

  programs.home-manager.enable = true;
}
