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
  ];
}
