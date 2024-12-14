{...}: {
  imports = [
    ./system/defaults.nix
    ./system/homebrew.nix
    ./system/packages.nix
    ./desktop/services.nix
  ];

  # Set ZSH
  programs.zsh.enable = true;

  # Enable TouchID for sudo
  security.pam.enableSudoTouchIdAuth = true;

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Used for backwards compatibility
  system.stateVersion = 5;
} 