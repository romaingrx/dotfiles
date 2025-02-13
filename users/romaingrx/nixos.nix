{ pkgs, ... }: {
  users.users.romaingrx = {
    isNormalUser = true;
    home = "/home/romaingrx";
    extraGroups = [ "wheel" "networkmanager" "video" "input" ];
    createHome = true;
    name = "romaingrx";
    hashedPassword =
      "$6$mvpn1IKZsbCfv5wU$aQxRPWCNlzkeln1KJBq5amMvWpo6mYk.q7ji8dMby6mRm/IY4SLWqDdFQSW7w0g0VRmxUEd1rPna.PggJV0is0";
  };

  # Enable Wayland compositor (Hyprland)
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

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
