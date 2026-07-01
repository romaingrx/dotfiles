{ pkgs, homeDirectory, ... }:
{
  imports = [
    ./homebrew.nix
    ./orbstack.nix
    ./services
  ];

  security.pam.services.sudo_local.touchIdAuth = true;

  nix.optimise.automatic = true;
  # Necessary for using flakes on this system.
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    max-jobs = "auto";
    cores = 0; # Use all available cores
    keep-derivations = true;
    keep-outputs = true;
  };

  system = {
    # Used for backwards compatibility
    stateVersion = 5;
    # activationScripts are executed every time you boot the system or run
    # `nixos-rebuild` / `darwin-rebuild`.
    activationScripts.extraActivation.text = ''
      # activateSettings -u will reload the settings from the database and
      # apply them to the current session, so we do not need to logout and
      # login again to make the changes take effect.
      # /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
      # sudo ln -sf "${pkgs.jdk17}/zulu-17.jdk" "/Library/Java/JavaVirtualMachines/"
    '';
    defaults = {
      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = false;
      };
      NSGlobalDomain = {
        KeyRepeat = 2;
        InitialKeyRepeat = 12;
        AppleShowAllFiles = true;
        AppleShowAllExtensions = true;
        ApplePressAndHoldEnabled = false;
        AppleInterfaceStyleSwitchesAutomatically = true;
        "com.apple.mouse.tapBehavior" = 1; # Is not working with trackpad
        _HIHideMenuBar = true;
        # Kills the half-second window resize/rebuild flash on AeroSpace workspace switches.
        NSAutomaticWindowAnimationsEnabled = false;
      };
      # com.apple.mouse.scaling is not a typed NSGlobalDomain option in nix-darwin,
      # so set the pointer tracking speed via the freeform CustomUserPreferences path.
      CustomUserPreferences.NSGlobalDomain."com.apple.mouse.scaling" = 0.875;
      # Dock stacks with an explicit sort order. arrangement: 1=Name, 2=Date
      # Added, 3=Date Modified, 4=Date Created, 5=Kind (date sorts are always
      # newest-first, i.e. descending). displayas: 1=folder. showas: 3=list.
      CustomUserPreferences."com.apple.dock".persistent-others =
        map
          (path: {
            tile-data = {
              file-data = {
                _CFURLString = "file://${path}/";
                _CFURLStringType = 15;
              };
              arrangement = 3;
              displayas = 1;
              showas = 3;
            };
            tile-type = "directory-tile";
          })
          [
            "${homeDirectory}/Downloads"
            "${homeDirectory}/Pictures/screenshots"
          ];
      dock = {
        autohide = true;
        orientation = "left";
        mru-spaces = false;
        minimize-to-application = true;
        show-process-indicators = true;
        persistent-apps = [
          "/System/Applications/Mail.app"
          "/System/Applications/Calendar.app"
          "${pkgs.raycast}/Applications/Raycast.app"
        ];
        # persistent-others is set via CustomUserPreferences below so we can
        # pin each stack's sort order (arrangement = 4 -> Date Created, newest
        # first). The typed option only accepts bare paths and can't express it.
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
      };
      screencapture = {
        location = "${homeDirectory}/Pictures/screenshots";
      };
      screensaver = {
        askForPasswordDelay = 0;
      };
    };
  };
}
