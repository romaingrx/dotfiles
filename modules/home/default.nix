{
  config,
  dotfilesPath,
  lib,
  ...
}:
let
  themeCommands = [
    "romaingrx-theme-apply"
    "romaingrx-theme-get"
    "romaingrx-theme-lib"
    "romaingrx-theme-set"
    "romaingrx-theme-watch"
  ];
  themeCommandFiles = builtins.listToAttrs (
    map (name: {
      inherit name;
      value = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/bin/${name}";
      };
    }) themeCommands
  );
in
{
  imports = [
    ./packages.nix
    ./programs.nix
  ];

  home = {
    stateVersion = "24.11";

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    file = lib.mapAttrs' (name: value: {
      name = ".local/bin/${name}";
      inherit value;
    }) themeCommandFiles;
  };

  programs.home-manager.enable = true;
}
