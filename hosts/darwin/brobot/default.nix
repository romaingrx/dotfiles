{ ... }:
{
  imports = [
    ../../../modules/darwin
  ];

  networking.hostName = "brobot";
  networking.computerName = "brobot";

  system.primaryUser = "romaingrx";

  system.defaults.loginwindow.LoginwindowText = "Hand-built, loyal, little brother";

  # MongoDB Compass GUI — brobot-only, list-merges with the shared casks.
  homebrew.casks = [ "mongodb-compass" ];

  # Host-only overrides live with the host:
  #   - system/darwin (dock, casks, macOS defaults) -> here, e.g.
  #       homebrew.casks = [ "some-app" ];                          # list-merges with the shared set
  #       system.defaults.dock.orientation = lib.mkForce "bottom";  # scalar -> mkForce to win
  #       (add `lib` to the arg set above if you use lib.* here)
  #   - home-manager (per-machine apps/programs) -> create ./home.nix
  #       beside this file; mkSystem auto-imports it when present.
}
