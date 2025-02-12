{ ... }: {
  imports = [ ./hardware-configuration.nix ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  networking = {
    hostName = "carl";
    networkmanager.enable = true;
  };

  time.timeZone = "Europe/Zurich";

  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver = {
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  system.stateVersion = "24.11";
}
