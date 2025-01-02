{...}: {
  imports = [
    ../../modules/darwin/defaults
    ../../modules/darwin/homebrew.nix
    ../../modules/darwin/packages.nix
  ];

  # Host-specific settings
  networking.hostName = "goddard";
  networking.computerName = "goddard";

  # Set ZSH
  programs.zsh.enable = true;

  # Enable TouchID for sudo
  security.pam.enableSudoTouchIdAuth = true;

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # The platform the configuration will be used on.
  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config.allowUnfree = true;
  };

  # Used for backwards compatibility
  system.stateVersion = 5;
} 