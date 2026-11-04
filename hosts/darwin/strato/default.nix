{ ... }:
{
  imports = [
    ../../../modules/darwin
  ];

  networking.hostName = "strato";
  networking.computerName = "strato";

  system.defaults.loginwindow.LoginwindowText = "Rocket-built, ready for liftoff";

  # Work-only GUI apps; list-merges with the shared casks.
  homebrew.casks = [
    # Docker; modules/darwin/orbstack.nix links its CLI.
    "orbstack"
    # Work Google account (passkey sign-in) in its own browser.
    "google-chrome"
  ];

  # The laptop is company-managed (MDM): nothing here should fight its
  # profiles (FileVault, firewall, updates).
}
