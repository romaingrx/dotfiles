{ ... }:
{
  imports = [
    ../../../modules/darwin
  ];

  networking.hostName = "goddard";
  networking.computerName = "goddard";

  system.primaryUser = "romaingrx";

  system.defaults.loginwindow.LoginwindowText = "Hi-tech, barking, Swiss army knife";
}
