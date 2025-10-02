{
  pkgs,
  lib,
  config,
  ...
}:
let
  mkFileWatcher = import ../../lib/mkFileWatcher.nix { inherit config pkgs lib; };
  configPath = "${config.home.homeDirectory}/.dotfiles/config";
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
        TERMINAL = "alacritty";
        BROWSER = "firefox";
      };
      sessionPath = [ "/home/romaingrx/.local/romaingrx-bin" ];
    };

    home.packages = with pkgs; [
      gcc
      uwsm
      swayosd
      hyprpaper
      rofi
      code-cursor
      hypridle
      hyprlock
      hyprland
      nautilus
      spotify
      signal-desktop
      lazydocker
      btop
      _1password-gui
      firefox
      cliphist
      wl-clipboard
    ];

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
        [ -d ~/.config/hypr ] || ln -sf ${configPath}/hypr ~/.config/hypr
        [ -d ~/.config/waybar ] || ln -sf ${configPath}/waybar ~/.config/waybar
        [ -d ~/.local/romaingrx-bin ] || ln -sf ${configPath}/bin ~/.local/romaingrx-bin
      '';
    };

    # Add Rofi configuration
    xdg.configFile."rofi/config.rasi".text = ''
      configuration {
        modi: "drun,run,window";
        show-icons: true;
        terminal: "alacritty";
        drun-display-format: "{icon} {name}";
        location: 0;
        disable-history: false;
        hide-scrollbar: true;
        display-drun: "   Apps ";
        display-run: "   Run ";
        display-window: " 﩯  Window";
        display-Network: " 󰤨  Network";
        sidebar-mode: true;
      }

      window {
        width: 1000px;
        border: 2px;
        border-color: #a597ca;
        border-radius: 10px;
        background-color: #1e1e2e;
      }

      mainbox {
        background-color: transparent;
      }

      inputbar {
        children: [prompt,entry];
        background-color: transparent;
        border-radius: 5px;
        padding: 2px;
      }

      prompt {
        background-color: #a597ca;
        padding: 6px;
        text-color: #1e1e2e;
        border-radius: 8px;
        margin: 20px 0px 0px 20px;
      }

      textbox-prompt-colon {
        expand: false;
        str: ":";
      }

      entry {
        padding: 6px;
        margin: 20px 0px 0px 10px;
        text-color: #a597ca;
        background-color: #1e1e2e;
      }

      listview {
        border: 0px 0px 0px;
        padding: 6px 0px 0px;
        margin: 10px 0px 0px 20px;
        columns: 2;
        background-color: transparent;
      }

      element {
        padding: 5px;
        background-color: transparent;
        text-color: #a597ca;
      }

      element-icon {
        size: 25px;
      }

      element selected {
        text-color: #1e1e2e;
        background-color: #a597ca;
        border-radius: 8px;
      }

      element-text {
        background-color: transparent;
        text-color: inherit;
        vertical-align: 0.5;
      }

      element-text selected {
        background-color: transparent;
      }
    '';
    wayland.windowManager.hyprland = {
      enable = true;
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
  })
]
