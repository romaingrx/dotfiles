{ pkgs, ... }:
let
  pinentryPackage =
    if pkgs.stdenv.isDarwin then pkgs.pinentry_mac else pkgs.pinentry-gtk2;
in {
  programs.gpg = {
    enable = true;
    settings = { trust-model = "tofu+pgp"; };
    # Enable gpg-agent with proper pinentry program
    mutableKeys = false;
    mutableTrust = false;

    # Configure gpg-agent
    scdaemonSettings = { disable-ccid = true; };

    publicKeys = [{ source = ./pubkeys/github.asc; }];
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    # Use OS specific pinentry
    pinentryPackage = pinentryPackage;
    defaultCacheTtl = 3600;
    maxCacheTtl = 7200;
    # Add extra configuration to help with the ioctl error
    extraConfig = ''
      allow-loopback-pinentry
    '';
  };

  # Add required environment variables
  home.sessionVariables = {
    GPG_TTY = "$(tty)";
    # Ensure proper GUI pinentry on Wayland
    PINENTRY_USER_DATA = "USE_TTY=1";
  };
}
