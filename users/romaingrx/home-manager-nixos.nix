{ pkgs, lib, ... }:
lib.mkIf pkgs.stdenv.isLinux {
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
      background = [
        {
          path = "~/.wallpapers/nixos.png";
          color = "rgba(25, 20, 20, 1.0)";
          blur_passes = 2;
          blur_size = 7;
          noise = 1.17e-2;
          contrast = 0.8916;
          brightness = 0.8172;
          vibrancy = 0.1696;
          vibrancy_darkness = 0.0;
        }
      ];
      input-field = [
        {
          size = "200, 50";
          position = "0, -80";
          monitor = "";
          dots_center = true;
          outer_color = "rgb(165, 151, 202)";
          inner_color = "rgb(30, 30, 46)";
          font_color = "rgb(200, 200, 200)";
          outline_thickness = 5;
          fade_on_empty = true;
          placeholder_text = "<i>Type to unlock...</i>";
          font_family = "JetBrainsMono Nerd Font";
          shadow_passes = 2;
        }
      ];
      label = [
        {
          text = "$TIME";
          color = "rgb(200, 200, 200)";
          font_size = 65;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, 140";
          halign = "center";
          valign = "center";
        }
      ];
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

  # Hyprland - Package only, config in dotfiles
  wayland.windowManager.hyprland = {
    enable = true;
    # Config moved to ~/.dotfiles/config/hyprland.conf
  };

  # Configure waybar - config in dotfiles
  programs.waybar = {
    enable = true;
    # Config moved to ~/.dotfiles/config/waybar.jsonc and ~/.dotfiles/config/waybar.css
  };

  # Symlink dotfiles configs
  xdg.configFile = {
    "hypr/hyprland.conf".source = ../../../.dotfiles/config/hyprland.conf;
    "waybar/config.jsonc".source = ../../../.dotfiles/config/waybar.jsonc;
    "waybar/style.css".source = ../../../.dotfiles/config/waybar.css;
    "hypr/hyprpaper.conf".source = ../../../.dotfiles/config/hyprpaper.conf;
    "hypr/hypridle.conf".source = ../../../.dotfiles/config/hypridle.conf;
    "hypr/hyprlock.conf".source = ../../../.dotfiles/config/hyprlock.conf;
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
