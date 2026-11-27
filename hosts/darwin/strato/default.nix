{ ... }:
{
  imports = [
    ../../../modules/darwin
    ../../../modules/darwin/herdr-app.nix
    ../../../modules/darwin/baton.nix
  ];

  networking.hostName = "strato";
  networking.computerName = "strato";

  system.defaults.loginwindow.LoginwindowText = "Rocket-built, always on trajectory";

  homebrew.casks = [
    "orbstack" # docker, linked by modules/darwin/orbstack.nix
    "google-chrome"
    "granola"
    "wispr-flow" # floats in AeroSpace (aerospace.toml)
  ];
}
