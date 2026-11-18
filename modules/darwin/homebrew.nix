{ config, lib, ... }:
let
  apps = import ../../lib/apps;
in
{
  # Install and manage Homebrew itself so a fresh host needs no manual brew
  # install; autoMigrate adopts an existing install (e.g. goddard).
  nix-homebrew = {
    enable = true;
    user = config.system.primaryUser;
    autoMigrate = true;
  };

  homebrew = {
    enable = true;
    global = { };
    onActivation = {
      cleanup = "uninstall";
      autoUpdate = false;
      upgrade = false;
    };

    # No Mac App Store apps — avoids requiring an App Store sign-in on a new host.
    masApps = { };
    taps = [ ];

    # Apps with a role (terminal, browser, ...) are installed from lib/apps.
    # Daily-driver GUI apps all ship a built-in updater (auto_updates), so
    # Homebrew only bootstraps them and onActivation.upgrade stays off.
    casks = [
      # FiraCode Nerd Font is installed from lib/theme via
      # modules/fonts.nix (pkgs.nerd-fonts.fira-code), so no cask is needed.
      "sf-symbols"
      "1password"
      "linear"
      "raycast"
      # Standalone, self-updating Tailscale GUI — replaces the Mac App Store
      # version so a fresh host needs no App Store sign-in. Same /Applications path.
      "tailscale-app"
    ]
    ++ lib.catAttrs "cask" (lib.attrValues apps.catalog);
    brews = [ ];
  };
}
