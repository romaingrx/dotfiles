{ ... }:
{
  imports = [
    ../../../modules/darwin
  ];

  networking.hostName = "strato";
  networking.computerName = "strato";

  system.defaults.loginwindow.LoginwindowText = "Rocket-built, always on trajectory";

  homebrew.casks = [
    "orbstack" # docker, linked by modules/darwin/orbstack.nix
    "google-chrome"
    "granola"
    "herdr-app" # GUI for the herdr CLI from nixpkgs master (home.nix)
  ];
}
