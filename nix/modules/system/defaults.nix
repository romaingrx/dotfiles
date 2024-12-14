{ pkgs, ... }: {


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
        _HIHideMenuBar = false;
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
        ];
        persistent-others = [
          "/Users/romaingrx/Downloads"
          "/Users/romaingrx/Pictures/screenshots"
        ];
      };
      finder = {
        FXPreferredViewStyle = "clmv";
        AppleShowAllExtensions = true;
      };
      loginwindow = {
        GuestEnabled = false;
        LoginwindowText = "Hi-tech, barking, Swiss army knife";
      };
      screencapture = {
        location = "/Users/romaingrx/Pictures/screenshots";
      };
      screensaver = {
        askForPasswordDelay = 0;
      };
    };
  };
  services = import ./services { inherit pkgs; };
}
