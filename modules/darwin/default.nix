{ config, lib, pkgs, ... }: {
  imports = [ ../common/external-packages.nix ];

  # System-level external packages configuration
  myConfig.externalPackages = {
    enable = true;
    homebrew = {
      enable = true;
      browsers.enable = true;
      productivity.enable = true;
      development.enable = true;
      media.enable = true;
    };
  };
}
