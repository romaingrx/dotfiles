# Wayland desktop (SDDM, xdg portals, PipeWire) for NixOS hosts with a screen.
{ pkgs, ... }:
{
  services = {
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    xserver.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  security = {
    rtkit.enable = true;
    pam.services.swaylock = { };
  };

  xdg.portal = {
    enable = true;
    config.common.default = [
      "wlr"
      "gtk"
    ];
    extraPortals = [
      pkgs.xdg-desktop-portal-wlr
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  # Draws the per-app icons on waybar's workspaces (modules/home/programs/waybar.nix).
  fonts.packages = [ pkgs.sketchybar-app-font ];

  environment.systemPackages = with pkgs; [
    wl-clipboard
    wf-recorder
    slurp
    grim
    swaylock
    swayidle
    wofi
    waybar
    swaynotificationcenter
    libnotify
    brightnessctl
    pamixer
    wdisplays
  ];
}
