{ config, pkgs, homeDirectory, ... }: {
  imports = [ ./homebrew.nix ./packages.nix ];

  # Enable TouchID for sudo
  security.pam.enableSudoTouchIdAuth = true;
  # Necessary for using flakes on this system.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # The platform the configuration will be used on.
  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config.allowUnfree = true;
  };

  system = {
    # Used for backwards compatibility
    stateVersion = 5;
    # activationScripts are executed every time you boot the system or run
    # `nixos-rebuild` / `darwin-rebuild`.
    activationScripts.postUserActivation.text = ''
      # activateSettings -u will reload the settings from the database and
      # apply them to the current session, so we do not need to logout and
      # login again to make the changes take effect.
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';
    defaults = {
      trackpad = { Clicking = true; };
      NSGlobalDomain = {
        KeyRepeat = 2;
        InitialKeyRepeat = 12;
        AppleShowAllFiles = true;
        AppleShowAllExtensions = true;
        ApplePressAndHoldEnabled = false;
        AppleInterfaceStyleSwitchesAutomatically = true;
        "com.apple.mouse.tapBehavior" = 1; # Is not working with trackpad
        _HIHideMenuBar = true;
      };
      dock = {
        autohide = true;
        orientation = "left";
        mru-spaces = false;
        minimize-to-application = true;
        show-process-indicators = true;
        persistent-apps = [
          "${pkgs.signal-desktop}/Applications/Signal.app"
          "/System/Applications/Mail.app"
          "/System/Applications/Calendar.app"
          "${pkgs.raycast}/Applications/Raycast.app"
        ];
        persistent-others = [
          "${homeDirectory}/Downloads"
          "${homeDirectory}/Pictures/screenshots"
        ];
      };
      finder = {
        FXPreferredViewStyle = "clmv";
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true; # Show hidden files
        ShowExternalHardDrivesOnDesktop = false;
        ShowHardDrivesOnDesktop = false;
        ShowMountedServersOnDesktop = false;
        ShowRemovableMediaOnDesktop = false;
        ShowPathbar = true;
      };
      loginwindow = { GuestEnabled = false; };
      screencapture = { location = "~/Pictures/screenshots"; };
      screensaver = { askForPasswordDelay = 0; };
    };
  };
  services = import ./services { inherit pkgs; };
}
