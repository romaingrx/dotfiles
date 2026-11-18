# What each app is: its category and how each platform identifies it. Facts
# only; preferences live in ./defaults.nix and placement in the window manager.
#
#   category  what kind of app it is (terminal, browser, ...)
#   bundleId  macOS app id
#   bin       Linux command
#   desktop   Linux desktop file
{
  ghostty = {
    category = "terminal";
    bundleId = "com.mitchellh.ghostty";
    bin = "ghostty";
  };
  terminal-app = {
    category = "terminal";
    bundleId = "com.apple.Terminal";
  };
  cursor = {
    category = "editor";
    bundleId = "com.todesktop.230313mzl4w4u92";
  };

  arc = {
    category = "browser";
    bundleId = "company.thebrowser.Browser";
  };
  firefox = {
    category = "browser";
    bundleId = "org.mozilla.firefox";
    bin = "firefox";
    desktop = "firefox.desktop";
  };
  chrome = {
    category = "browser";
    bundleId = "com.google.Chrome";
  };
  safari = {
    category = "browser";
    bundleId = "com.apple.Safari";
  };
  duckduckgo = {
    category = "browser";
    bundleId = "com.duckduckgo.macos.browser";
  };

  mail = {
    category = "social";
    bundleId = "com.apple.Mail";
  };
  slack = {
    category = "social";
    bundleId = "com.tinyspeck.slackmacgap";
  };
  signal = {
    category = "social";
    bundleId = "org.whispersystems.signal-desktop";
  };

  obsidian = {
    category = "utility";
    bundleId = "md.obsidian";
  };
  notion = {
    category = "utility";
    bundleId = "notion.id";
  };
  claude = {
    category = "utility";
    bundleId = "com.anthropic.claudefordesktop";
  };
  finder = {
    category = "utility";
    bundleId = "com.apple.finder";
  };

  spotify = {
    category = "music";
    bundleId = "com.spotify.client";
  };
}
