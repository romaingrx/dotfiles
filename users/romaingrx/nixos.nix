{ pkgs, ... }:
{
  users.users.romaingrx = {
    isNormalUser = true;
    home = "/home/romaingrx";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "input"
      "docker"
    ];
    shell = pkgs.zsh;
    createHome = true;
    name = "romaingrx";
    # hashedPassword = "$6$mvpn1IKZsbCfv5wU$aQxRPWCNlzkeln1KJBq5amMvWpo6mYk.q7ji8dMby6mRm/IY4SLWqDdFQSW7w0g0VRmxUEd1rPna.PggJV0is0";
    hashedPassword = "$y$j9T$qVU7uRmv/gNOZsnlYaCAv0$XZ3H.Mr/xiiIcW0HK9ffOOX4pOebhZzPIpQz7ZYv/s4";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBkfSToevrwCevzebA9iNrCGxoXuPBnAW3uFNSuJqcef me@romaingrx.com"
    ];
  };

  fonts.packages = with pkgs; [ nerd-fonts.fira-code ];

  # TODO romaingrx: Make sure that the programs are user specific
  programs.zsh.enable = true;

  virtualisation.docker.enable = true;

  # Enable Wayland compositor (Hyprland)
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Enable display manager
  services.xserver = {
    enable = true; # needed for SDDM
    displayManager.sddm = {
      enable = true;
      wayland.enable = true; # Enable Wayland support in SDDM
    };
  };

  # Wayland-specific packages
  environment.systemPackages = with pkgs; [
    # Core Wayland utilities
    wl-clipboard
    wf-recorder
    slurp
    grim # screenshot
    swaylock # lockscreen
    swayidle
    wofi # application launcher
    waybar # status bar
    dunst # notification daemon
    libnotify
    brightnessctl # brightness control
    pamixer # pulseaudio control
    wdisplays # Display settings GUI for Wayland
  ];

  # Enable common Wayland programs
  security.pam.services.swaylock = { };
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  # Enable sound
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}
