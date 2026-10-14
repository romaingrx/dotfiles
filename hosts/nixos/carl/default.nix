# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  programs.nix-ld.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  environment.systemPackages = with pkgs.cudaPackages; [
    cudatoolkit
    cudnn
    nccl
    libcublas
  ];

  services = {
    tailscale.enable = true;
    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
      xkb = {
        layout = "us";
        variant = "";
      };
    };
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };
    qemuGuest.enable = true;
  };

  networking = {
    # sshd opens its own port; the tailnet is trusted as a whole.
    firewall.trustedInterfaces = [ "tailscale0" ];
    hostName = "carl";
    interfaces.ens18 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "10.42.0.4";
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = "10.42.0.1";
    nameservers = [ "10.42.0.1" ];
  };
  time.timeZone = "Europe/Zurich";
  i18n.defaultLocale = "en_US.UTF-8";

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    nvidia = {
      modesetting.enable = true;
      open = true;
      nvidiaSettings = true;
      powerManagement.enable = true;
    };
    # nvidia-container-toolkit.enable = true;
    bluetooth = {
      enable = true;
    };
    logitech = {
      wireless = {
        enable = true;
        enableGraphical = true;
      };
    };
  };

  system.stateVersion = "25.11";
}
