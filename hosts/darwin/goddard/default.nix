{ ... }: {
  imports = [ ../../../modules/core/darwin ];

  # Host-specific settings
  networking.hostName = "goddard";
  networking.computerName = "goddard";

  # System-specific settings
  system.defaults.loginwindow.LoginwindowText =
    "Hi-tech, barking, Swiss army knife";
}
