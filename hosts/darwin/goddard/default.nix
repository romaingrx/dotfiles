{ ... }:
{
  imports = [
    ../../../modules/darwin
  ];

  networking.hostName = "goddard";
  networking.computerName = "goddard";

  system.defaults.loginwindow.LoginwindowText = "Hi-tech, barking, Swiss army knife";
}
