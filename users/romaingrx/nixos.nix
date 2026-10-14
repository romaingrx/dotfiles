{ pkgs, ... }:
{
  users.users.romaingrx = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "input"
      "docker"
    ];
    shell = pkgs.zsh;
    hashedPassword = "$y$j9T$qVU7uRmv/gNOZsnlYaCAv0$XZ3H.Mr/xiiIcW0HK9ffOOX4pOebhZzPIpQz7ZYv/s4";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBkfSToevrwCevzebA9iNrCGxoXuPBnAW3uFNSuJqcef me@romaingrx.com"
    ];
  };

  programs.zsh.enable = true;
}
