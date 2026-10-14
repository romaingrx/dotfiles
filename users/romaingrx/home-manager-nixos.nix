{
  pkgs,
  lib,
  config,
  dotfilesPath,
  ...
}:
let
  configPath = "${dotfilesPath}/config";
in
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
      # Preferences
      TERMINAL = "alacritty";
      BROWSER = "firefox";
      XDG_PICTURES_DIR = "${config.home.homeDirectory}/Pictures";
    };
    sessionPath = [ "${config.home.homeDirectory}/.local/romaingrx-bin" ];
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
    obsidian
    slack
  ];

  # home.pointerCursor = {
  #   package = pkgs.bibata-cursors;
  #   name = "Bibata-Modern-Classic";
  #   size = 24;
  #   gtk.enable = true;
  # };

  home.file.".profile".text = ''
    if uwsm check may-start && uwsm select; then
      exec uwsm start default
    fi
  '';

  # Link wallpaper from dotfiles to the home directory
  home.file.".wallpapers/nixos.png".source = ../../assets/wallpapers/nixos.png;

  # Expose the dotfiles config/bin scripts on PATH via an out-of-store symlink
  # (managed by Home Manager rather than a hand-rolled activation script).
  home.file.".local/romaingrx-bin".source = config.lib.file.mkOutOfStoreSymlink "${configPath}/bin";

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
}
