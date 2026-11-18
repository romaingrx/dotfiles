# The one place apps are given a role. Change a default and rebuild to swap
# the terminal or browser everywhere: launch keys, workspace rules, $TERMINAL,
# $BROWSER, the Linux default browser and the Homebrew install.
#
# An app is listed here only when something else must know about it. Fields:
#   role      picks the AeroSpace workspace (see `workspaces`)
#   bundleId  macOS app id, matched by AeroSpace and opened by launch keys
#   cask      Homebrew cask installed on every macOS host
#   bin       Linux command, for $TERMINAL / $BROWSER
#   desktop   Linux desktop file, for the default browser
rec {
  default = {
    terminal = "ghostty";
    # Arc has no Linux build.
    browser = {
      darwin = "arc";
      linux = "firefox";
    };
  };

  workspaces = {
    terminal = "C";
    editor = "C";
    browser = "B";
    social = "S";
    utility = "U";
    music = "M";
  };

  catalog = {
    ghostty = {
      role = "terminal";
      bundleId = "com.mitchellh.ghostty";
      cask = "ghostty";
      bin = "ghostty";
    };
    terminal-app = {
      role = "terminal";
      bundleId = "com.apple.Terminal";
    };
    cursor = {
      role = "editor";
      bundleId = "com.todesktop.230313mzl4w4u92";
    };

    arc = {
      role = "browser";
      bundleId = "company.thebrowser.Browser";
      cask = "arc";
    };
    firefox = {
      role = "browser";
      bundleId = "org.mozilla.firefox";
      cask = "firefox";
      bin = "firefox";
      desktop = "firefox.desktop";
    };
    # Installed per host (strato).
    chrome = {
      role = "browser";
      bundleId = "com.google.Chrome";
    };
    safari = {
      role = "browser";
      bundleId = "com.apple.Safari";
    };
    duckduckgo = {
      role = "browser";
      bundleId = "com.duckduckgo.macos.browser";
    };

    mail = {
      role = "social";
      bundleId = "com.apple.Mail";
    };
    slack = {
      role = "social";
      bundleId = "com.tinyspeck.slackmacgap";
      cask = "slack";
    };
    signal = {
      role = "social";
      bundleId = "org.whispersystems.signal-desktop";
    };

    obsidian = {
      role = "utility";
      bundleId = "md.obsidian";
      cask = "obsidian";
    };
    notion = {
      role = "utility";
      bundleId = "notion.id";
    };
    claude = {
      role = "utility";
      bundleId = "com.anthropic.claudefordesktop";
      cask = "claude";
    };
    finder = {
      role = "utility";
      bundleId = "com.apple.finder";
    };

    spotify = {
      role = "music";
      bundleId = "com.spotify.client";
      cask = "spotify";
    };
  };

  # The resolved defaults, for consumers.
  terminal = catalog.${default.terminal};
  browser = builtins.mapAttrs (_: name: catalog.${name}) default.browser;
}
