{ pkgs, config, ... }: {
  imports = [
    ./homebrew.nix
    ./packages.nix
  ];

  system = {
    # activationScripts are executed every time you boot the system or run
    # `nixos-rebuild` / `darwin-rebuild`.
    activationScripts.postUserActivation.text = ''
      # activateSettings -u will reload the settings from the database and
      # apply them to the current session, so we do not need to logout and
      # login again to make the changes take effect.
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';
    defaults = {
      trackpad = {
        Clicking = true;
      };
      NSGlobalDomain = {
        KeyRepeat = 2;
        InitialKeyRepeat = 12;
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
          "~/Downloads"
          "~/Pictures/screenshots"
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
      loginwindow = {
        GuestEnabled = false;
        LoginwindowText = "Hi-tech, barking, Swiss army knife";
      };
      screencapture = {
        location = "~/Pictures/screenshots";
      };
      screensaver = {
        askForPasswordDelay = 0;
      };
    };
  };
  services = import ./services { inherit pkgs; };
}
