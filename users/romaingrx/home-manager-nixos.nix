{
  pkgs,
  lib,
  config,
  dotfilesPath,
  ...
}:
let
  mkFileWatcher = import ../../lib/mkFileWatcher.nix { inherit config pkgs lib; };
  configPath = "${dotfilesPath}/config";
in
lib.mkMerge [
  (mkFileWatcher {
    name = "waybar";
    serviceName = "waybar";
    restartCommand = ''
      pkill waybar
      sleep 0.2
      waybar &
    '';
    watchPaths = [ "/home/romaingrx/.config/waybar/" ];
    description = "Waybar with auto-restart on config changes";

  })
  (mkFileWatcher {
    name = "hyprctl";
    description = "Hyprland with auto-restart on config changes";
    serviceName = "hyprctl";
    restartCommand = ''
      systemctl --user restart hyprpaper
      systemctl --user restart hypridle
      hyprctl reload
    '';
    watchPaths = [ "/home/romaingrx/.config/hypr/" ];
    recursive = true;
  })
  (lib.mkIf pkgs.stdenv.isLinux {
    home = {
      sessionVariables = {
        # Wayland specific
        XDG_CURRENT_DESKTOP = "Hyprland";
        XDG_SESSION_TYPE = "wayland";
        XDG_SESSION_DESKTOP = "Hyprland";
        # Toolkit Backend Variables
        QT_QPA_PLATFORM = "wayland;xcb";
        QT_AUTO_SCREEN_SCALE_FACTOR = "1";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        GDK_BACKEND = "wayland";
        SDL_VIDEODRIVER = "wayland";
        CLUTTER_BACKEND = "wayland";
        # Preferences
        TERMINAL = "alacritty";
        BROWSER = "firefox";
        XDG_PICTURES_DIR = "/home/romaingrx/Pictures";
      };
      sessionPath = [ "/home/romaingrx/.local/romaingrx-bin" ];
    };

    home.packages = with pkgs; [
      gcc
      uwsm
      swayosd
      hyprpaper
      rofi
      hypridle
      hyprlock
      hyprland
      hyprshot
      nautilus
      cliphist
      wl-clipboard
      bibata-cursors
      spotify
      signal-desktop
      lazydocker
      btop
      _1password-gui
      firefox
      thunderbird-latest
    ];

    # home.pointerCursor = {
    #   package = pkgs.bibata-cursors;
    #   name = "Bibata-Modern-Classic";
    #   size = 24;
    #   gtk.enable = true;
    # };

    # TODO: Fix this, it's not clean
    programs.zsh.initContent = ''
      # Script to set HYPRLAND_INSTANCE_SIGNATURE for hyprctl
        # Function to automatically set HYPRLAND_INSTANCE_SIGNATURE for hyprctl
        # Check if HYPRLAND_INSTANCE_SIGNATURE is already set
        if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
          # Try to find the Hyprland instance signature
          if [ -n "$XDG_RUNTIME_DIR" ] && [ -d "$XDG_RUNTIME_DIR/hypr" ]; then
            INSTANCE_SIG=$(ls "$XDG_RUNTIME_DIR/hypr" 2>/dev/null | head -1)
            if [ -n "$INSTANCE_SIG" ]; then
              export HYPRLAND_INSTANCE_SIGNATURE="$INSTANCE_SIG"
            fi
          fi
        fi
        export PATH="''${PATH}:/home/romaingrx/.local/romaingrx-bin"
    '';

    home.file.".profile".text = ''
      if uwsm check may-start && uwsm select; then
        exec uwsm start default
      fi
    '';

    # Link wallpaper from dotfiles to the home directory
    home.file.".wallpapers/nixos.png".source = ../../assets/wallpapers/nixos.png;

    home.activation = {
      text = ''
        [ -d ~/.local/romaingrx-bin ] || ln -sf ${configPath}/bin ~/.local/romaingrx-bin
      '';
    };

    wayland.windowManager.hyprland = {
      enable = true;
      configType = "hyprlang";
      extraConfig = ''
        source = ~/.config/hypr/hyprland-core.conf
      '';
    };

    # Clipboard history service
    systemd.user.services.cliphist = {
      Unit = {
        Description = "Clipboard history service";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store";
        Restart = "always";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    systemd.user.services.appearance-theme-switcher = {
      Unit = {
        Description = "Appearance theme state and consumer synchronization";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.bash}/bin/bash ${config.home.homeDirectory}/.local/bin/romaingrx-theme-watch";
        Restart = "always";
        RestartSec = 3;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  })
]
