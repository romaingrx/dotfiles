{ ... }:
{
  imports = [
    ../../../modules/darwin
  ];

  networking.hostName = "strato";
  networking.computerName = "strato";

  system.defaults.loginwindow.LoginwindowText = "Rocket-built, ready for liftoff";

  # strato-only GUI apps; list-merges with the shared casks.
  homebrew.casks = [
    # Docker for local `tl run`; modules/darwin/orbstack.nix links its CLI.
    "orbstack"
    # Google Workspace (passkey sign-in) in its own browser.
    "google-chrome"
  ];

  # The laptop is enrolled in the company MDM: nothing here should
  # fight its profiles (FileVault, firewall, updates).
}
