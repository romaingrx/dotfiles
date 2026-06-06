{
  config,
  dotfilesPath,
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
  themeCommandFile = name: {
    name = ".local/bin/${name}";
    value.source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/bin/${name}";
  };
in
{
  imports = [
    ./packages.nix
    ./programs.nix
    ./theme.nix
  ];

  home = {
    stateVersion = "24.11";

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    file = builtins.listToAttrs (map themeCommandFile themeCommands);
  };

  programs.home-manager.enable = true;
}
