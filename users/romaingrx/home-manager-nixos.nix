{ pkgs, ... }: {
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
    };
  };

  home.packages = with pkgs; [
    hyprpaper
    rofi-wayland
    code-cursor
    hypridle
    hyprlock
  ];

  # Link wallpaper from dotfiles to the home directory
  home.file.".wallpapers/nixos.png".source = ../../assets/wallpapers/nixos.png;

  # Create hyprpaper config file
  xdg.configFile."hypr/hyprpaper.conf".text = ''
    preload = ~/.wallpapers/nixos.png
    wallpaper = ,~/.wallpapers/nixos.png
    ipc = off
  '';

  # Configure hyprlock
  programs.hyprlock = {
    enable = true;
    package = pkgs.hyprlock;
    settings = {
      general = {
        disable_loading_bar = false;
        hide_cursor = true;
        grace = 0;
        no_fade_in = false;
      };
      background = [{
        path = "~/.wallpapers/nixos.png";
        color = "rgba(25, 20, 20, 1.0)";
        blur_passes = 2;
        blur_size = 7;
        noise = 1.17e-2;
        contrast = 0.8916;
        brightness = 0.8172;
        vibrancy = 0.1696;
        vibrancy_darkness = 0.0;
      }];
      input-field = [{
        size = "200, 50";
        position = "0, -80";
        monitor = "";
        dots_center = true;
        fade_on_empty = false;
        outer_color = "rgb(165, 151, 202)";
        inner_color = "rgb(30, 30, 46)";
        font_color = "rgb(200, 200, 200)";
        outline_thickness = 5;
        placeholder_text = "Type to unlock...";
        shadow_passes = 2;
      }];
    };
  };

  # Configure hypridle
  xdg.configFile."hypr/hypridle.conf".text = ''
    general {
        lock_cmd = pidof hyprlock || hyprlock     # avoid starting multiple hyprlock instances
        before_sleep_cmd = loginctl lock-session  # lock before suspend
        after_sleep_cmd = hyprctl dispatch dpms on  # to avoid having to press a key twice to turn on the display
    }

    listener {
        timeout = 150                                # 2.5min
        on-timeout = brightnessctl -s set 10        # set monitor backlight to minimum
        on-resume = brightnessctl -r                # monitor backlight restore
    }

    listener {
        timeout = 300                               # 5min
        on-timeout = loginctl lock-session          # lock screen when timeout has passed
    }

    listener {
        timeout = 330                               # 5.5min
        on-timeout = hyprctl dispatch dpms off      # screen off when timeout has passed
        on-resume = hyprctl dispatch dpms on        # screen on when activity is detected
    }

    listener {
        timeout = 1800                              # 30min
        on-timeout = systemctl suspend              # suspend pc
    }
  '';

  # Hyprland Configuration
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      # Monitor configuration
      monitor = [
        ",preferred,auto,1" # Default monitor configuration
      ];

      # General configuration
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(a597caee) rgba(b3d8faee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "dwindle";
      };

      # Dwindle layout configuration
      dwindle = {
        pseudotile = true;
        preserve_split = true;
        force_split =
          2; # 0 = split follows mouse, 1 = always split to the left/top, 2 = always split to the right/bottom
        default_split_ratio = 1.0; # default split ratio when opening a window
        use_active_for_splits = true;
        special_scale_factor = 0.8;
      };

      # Decoration configuration
      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
        };
      };

      # Animation configuration
      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      # Input configuration
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = { natural_scroll = true; };
        sensitivity = 0;
      };

      # Gestures
      gestures = { workspace_swipe = true; };

      # Window rules
      windowrule = [
        "float,^(pavucontrol)$"
        "float,^(nm-connection-editor)$"
        "float,^(chromium)$"
        "float,^(thunar)$"
        "float,title:^(btop)$"
        "float,title:^(update-sys)$"
      ];

      # Key bindings
      "$mod" = "SUPER";
      bind = [
        # Basic bindings
        "$mod, Return, exec, alacritty"
        "$mod, Q, killactive,"
        "$mod, M, exit,"
        "$mod, E, exec, thunar"
        "$mod, V, togglefloating,"
        "$mod, R, exec, rofi -show drun"
        "$mod, P, pseudo,"
        "$mod, D, togglesplit,"
        "$mod, L, exec, hyprlock"

        # Move focus
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        # Move focus with vim-style bindings as well
        "$mod, h, movefocus, l"
        "$mod, l, movefocus, r"
        "$mod, k, movefocus, u"
        "$mod, j, movefocus, d"

        # Switch workspaces
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"

        # Move active window to workspace
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"

        # Screenshots
        '', Print, exec, grim -g "$(slurp)" - | wl-copy''
        ''SHIFT, Print, exec, grim -g "$(slurp)"''
      ];

      # Mouse bindings
      bindm = [
        # Move/resize windows with mod + LMB/RMB and dragging
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # Startup applications
      exec-once = [ "dunst" "hyprpaper" "hypridle" ];
    };
  };

  # Configure waybar
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        spacing = 4;
        margin-top = 6;
        margin-left = 8;
        margin-right = 8;

        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "clock" ];
        modules-right =
          [ "pulseaudio" "network" "cpu" "memory" "battery" "tray" ];

        "hyprland/workspaces" = {
          format = "{icon}";
          on-click = "activate";
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            "6" = "6";
            "7" = "7";
            "8" = "8";
            "9" = "9";
            "10" = "10";
          };
          sort-by-number = true;
        };

        "hyprland/window" = {
          format = "{}";
          max-length = 50;
        };

        "clock" = {
          format = "{:%H:%M}";
          format-alt = "{:%Y-%m-%d %H:%M:%S}";
          tooltip-format = ''
            <big>{:%Y %B}</big>
            <tt><small>{calendar}</small></tt>'';
        };

        "cpu" = {
          format = "  {usage}%";
          tooltip = false;
          interval = 1;
        };

        "memory" = {
          format = "  {}%";
          interval = 1;
        };

        "network" = {
          format-wifi = "  {essid}";
          format-ethernet = "  Connected";
          format-disconnected = "⚠  Disconnected";
          tooltip-format = "{ifname} via {gwaddr}";
          tooltip-format-wifi = "{essid} ({signalStrength}%)";
        };

        "pulseaudio" = {
          format = "{icon}  {volume}%";
          format-bluetooth = "{icon}  {volume}%";
          format-bluetooth-muted = "   {volume}%";
          format-muted = "  {volume}%";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = [ "" "" "" ];
          };
          on-click = "pavucontrol";
        };

        "tray" = {
          icon-size = 18;
          spacing = 10;
        };
      };
    };

    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: "JetBrainsMono Nerd Font";
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background: rgba(21, 18, 27, 0);
        color: #a597ca;
      }

      tooltip {
        background: #1e1e2e;
        border-radius: 10px;
        border-width: 2px;
        border-style: solid;
        border-color: #11111b;
      }

      #workspaces button {
        padding: 5px;
        color: #313244;
        margin-right: 5px;
      }

      #workspaces button.active {
        color: #a6adc8;
      }

      #workspaces button.focused {
        color: #a6adc8;
        background: #eba0ac;
        border-radius: 10px;
      }

      #workspaces button.urgent {
        color: #11111b;
        background: #a6e3a1;
        border-radius: 10px;
      }

      #workspaces button:hover {
        background: #11111b;
        color: #cdd6f4;
        border-radius: 10px;
      }

      #window,
      #clock,
      #pulseaudio,
      #network,
      #cpu,
      #memory,
      #tray {
        background: #1e1e2e;
        padding: 0px 10px;
        margin: 3px 0px;
        margin-top: 10px;
        border: 1px solid #181825;
      }

      #tray {
        border-radius: 10px;
        margin-right: 10px;
      }

      #workspaces {
        background: #1e1e2e;
        border-radius: 10px;
        margin-left: 10px;
        padding-right: 0px;
        padding-left: 5px;
      }

      #window {
        border-radius: 10px;
        margin-left: 60px;
        margin-right: 60px;
      }

      #clock {
        color: #fab387;
        border-radius: 10px 10px 10px 10px;
        margin-left: 5px;
        border-right: 0px;
      }

      #network {
        color: #f9e2af;
        border-radius: 10px 0px 0px 10px;
        border-left: 0px;
        border-right: 0px;
      }

      #memory {
        color: #89b4fa;
        border-radius: 10px 0px 0px 10px;
        border-left: 0px;
        border-right: 0px;
      }

      #cpu {
        color: #94e2d5;
        border-left: 0px;
        border-right: 0px;
      }

      #battery {
        color: #a6e3a1;
        border-radius: 0 10px 10px 0;
        margin-right: 10px;
        border-left: 0px;
      }

      #pulseaudio {
        color: #89b4fa;
        border-left: 0px;
        border-right: 0px;
      }
    '';
  };

  # Add Rofi configuration
  xdg.configFile."rofi/themes/catppuccin-mocha.rasi".text = ''
    * {
      bg-col: #1e1e2e;
      bg-col-light: #1e1e2e;
      border-col: #a597ca;
      selected-col: #1e1e2e;
      blue: #89b4fa;
      fg-col: #cdd6f4;
      fg-col2: #1e1e2e;
      grey: #6c7086;
      width: 600;
    }

    element-text, element-icon , mode-switcher {
      background-color: inherit;
      text-color: inherit;
    }

    window {
      height: 360px;
      border: 3px;
      border-color: @border-col;
      background-color: @bg-col;
    }

    mainbox {
      background-color: @bg-col;
    }

    inputbar {
      children: [prompt,entry];
      background-color: @bg-col;
      border-radius: 5px;
      padding: 2px;
    }

    prompt {
      background-color: @blue;
      padding: 6px;
      text-color: @bg-col;
      border-radius: 3px;
      margin: 20px 0px 0px 20px;
    }

    textbox-prompt-colon {
      expand: false;
      str: ":";
    }

    entry {
      padding: 6px;
      margin: 20px 0px 0px 10px;
      text-color: @fg-col;
      background-color: @bg-col;
    }

    listview {
      border: 0px 0px 0px;
      padding: 6px 0px 0px;
      margin: 10px 0px 0px 20px;
      columns: 2;
      lines: 5;
      background-color: @bg-col;
    }

    element {
      padding: 5px;
      background-color: @bg-col;
      text-color: @fg-col  ;
    }

    element-icon {
      size: 25px;
    }

    element selected {
      background-color:  @selected-col ;
      text-color: @blue  ;
    }

    mode-switcher {
      spacing: 0;
    }

    button {
      padding: 10px;
      background-color: @bg-col-light;
      text-color: @grey;
      vertical-align: 0.5; 
      horizontal-align: 0.5;
    }

    button selected {
      background-color: @bg-col;
      text-color: @blue;
    }
  '';

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

    @theme "themes/catppuccin-mocha"

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
}
