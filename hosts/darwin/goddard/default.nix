{ ... }: {
  imports = [ ../../../modules/core/darwin ];

  # Host-specific settings
  networking.hostName = "goddard";
  networking.computerName = "goddard";

  # System-specific settings
  system.defaults.loginwindow.LoginwindowText =
    "Hi-tech, barking, Swiss army knife";

  # Enable proxy service
  services.mitmproxy = {
    enable = true;
    port = 8080;
    interfaces = [ "Wi-Fi" "USB 10/100/1000 LAN" ];
    # Uncomment if you have an upstream proxy
    # upstreamProxy = "http://proxy.example.com:8080";
  };
}
