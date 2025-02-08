{ config, pkgs, homeDirectory }: {
  imports = [
    (import ../../../modules/core/darwin { inherit pkgs config homeDirectory; })
  ];

  # Host-specific settings
  networking.hostName = "goddard";
  networking.computerName = "goddard";

  # System-specific settings
  system.defaults.loginwindow.LoginwindowText =
    "Hi-tech, barking, Swiss army knife";
}
