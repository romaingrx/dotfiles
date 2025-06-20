{ pkgs, ... }: {
  imports = [
    ../../../modules/core/darwin
    ../../../modules/darwin
    ../../../modules/services
  ];

  # Host-specific settings
  networking.hostName = "goddard";
  networking.computerName = "goddard";

  # System-specific settings
  system.defaults.loginwindow.LoginwindowText =
    "Hi-tech, barking, Swiss army knife";

  # Modern service configuration using abstractions
  myServices = {
    enable = true;

    # SketchyBar with clean configuration
    sketchybar = {
      enable = true;
      package = pkgs.sketchybar;
      configDir = let
        sbarLua = pkgs.stdenv.mkDerivation rec {
          pname = "sketchybar-lua";
          version = "0.1.0";
          src = pkgs.fetchFromGitHub {
            owner = "FelixKratz";
            repo = "SbarLua";
            rev = "main";
            sha256 = "sha256-F0UfNxHM389GhiPQ6/GFbeKQq5EvpiqQdvyf7ygzkPg=";
          };
          nativeBuildInputs = [ pkgs.gcc ];
          buildInputs = with pkgs; [
            lua
            readline
            darwin.apple_sdk.frameworks.CoreFoundation
          ];
          preBuildPhase = ''
            substituteInPlace makefile \
              --replace "cd lua-5.4.7 && make" "echo 'Skipping lua build...'" \
              --replace "bin/liblua.a" ""
          '';
          buildPhase = ''
            mkdir -p bin
            $CC -shared -o libsketchybar.so src/*.c \
              -I${pkgs.lua}/include -L${pkgs.lua}/lib -llua \
              -framework CoreFoundation
          '';
          installPhase = ''
            mkdir -p $out/lib
            cp libsketchybar.so $out/lib/
          '';
        };
      in pkgs.runCommand "sketchybar-config" { } ''
        mkdir -p $out
        cp -r ${../../../modules/core/darwin/services/sketchybar/config}/* $out/
        mkdir -p $out/lib
        ln -s ${sbarLua}/lib/libsketchybar.so $out/lib/sketchybar.so
      '';
    };

    # AeroSpace window manager
    aerospace = {
      enable = true;
      package = pkgs.aerospace;
      settings = pkgs.lib.importTOML
        ../../../modules/core/darwin/services/aerospace/aerospace.toml;
    };

    # JankyBorders with customization
    jankyborders = {
      enable = true;
      package = pkgs.jankyborders;
      width = 6;
      hidpi = true;
    };

    # Mitmproxy with modern configuration
    mitmproxy = {
      enable = true;
      package = pkgs.mitmproxy;
      port = 8080;
      interfaces = [ "Wi-Fi" "USB 10/100/1000 LAN" ];
    };
  };

  # Keep Tailscale using the native nix-darwin service
  services.tailscale.enable = true;

  # Additional system configuration with modern patterns
  system.defaults = {
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
    };

    finder = {
      FXPreferredViewStyle = "clmv";
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      ShowPathbar = true;
    };

    NSGlobalDomain = {
      KeyRepeat = 2;
      InitialKeyRepeat = 12;
      AppleShowAllFiles = true;
      AppleShowAllExtensions = true;
      ApplePressAndHoldEnabled = false;
      AppleInterfaceStyleSwitchesAutomatically = true;
      "com.apple.mouse.tapBehavior" = 1;
      _HIHideMenuBar = true;
    };
  };
}
