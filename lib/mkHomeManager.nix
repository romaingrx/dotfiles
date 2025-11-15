# Home Manager configuration builder
# Provides reusable profiles and feature sets for users
{ lib, ... }:

{
  # User identification
  username,
  fullName ? username,
  email ? "${username}@users.noreply.github.com",

  # Home configuration
  homeDirectory,
  stateVersion ? "24.11",

  # Feature flags for granular control
  features ? { },

  # Profile selection (development, productivity, media, etc.)
  profiles ? [ ],

  # Package categories
  packages ? { },

  # Program configurations
  programs ? { },

  # Service configurations
  services ? { },

  # Additional imports
  extraImports ? [ ],

  # Platform-specific overrides
  platformOverrides ? { },
}:

let
  # Available feature flags with defaults
  defaultFeatures = {
    development = false;
    productivity = false;
    media = false;
    gaming = false;
    design = false;
    security = false;
  };

  # Available profiles that enable feature combinations
  profileFeatures = {
    minimal = { };
    developer = {
      development = true;
      productivity = true;
      security = true;
    };
    creative = {
      development = true;
      productivity = true;
      media = true;
      design = true;
    };
    power-user = {
      development = true;
      productivity = true;
      media = true;
      security = true;
    };
    gamer = {
      productivity = true;
      media = true;
      gaming = true;
    };
  };

  # Merge profile features with explicit features
  enabledProfiles = lib.foldl' (
    acc: profile: acc // (profileFeatures.${profile} or { })
  ) { } profiles;
  finalFeatures = defaultFeatures // enabledProfiles // features;

  # Default package categories based on features
  defaultPackages = {
    core.enable = true;
    development.enable = finalFeatures.development;
    productivity.enable = finalFeatures.productivity;
    media.enable = finalFeatures.media;
    extraPackages = [ ];
  };

  # Default program configurations
  defaultPrograms = {
    enable = true;
    git = {
      enable = true;
      userName = fullName;
      userEmail = email;
    };
    zsh = {
      enable = true;
      features = finalFeatures;
    };
    tmux.enable = finalFeatures.development;
    gpg.enable = finalFeatures.security;
  };

  # Default service configurations
  defaultServices = {
    enable = false;
  };

  # Platform-specific configurations
  platformConfig = if lib.pathExists ../platforms then import ../platforms { inherit lib; } else { };

in
{
  imports = [
    # Base common configuration
    ../modules/common

    # Feature-based imports
  ]
  ++ lib.optionals finalFeatures.development [ ../modules/development ]
  ++ lib.optionals finalFeatures.productivity [ ../modules/productivity ]
  ++ lib.optionals finalFeatures.media [ ../modules/media ]
  ++ lib.optionals finalFeatures.security [ ../modules/security ]
  ++ extraImports;

  # Base home configuration
  home = {
    inherit username stateVersion;
    homeDirectory = homeDirectory;
  };

  # Apply configuration through the new option system
  myConfig = {
    common = {
      enable = true;
      stateVersion = stateVersion;
    };

    # Package configuration
    packages = defaultPackages // packages;

    # Program configuration
    programs = defaultPrograms // programs;

    # Service configuration
    services = defaultServices // services;
  };

  # Feature-specific configurations
  config = lib.mkMerge [
    # Development features
    (lib.mkIf finalFeatures.development {
      myConfig.systemPackages = {
        enable = true;
        development.enable = true;
      };
    })

    # Security features
    (lib.mkIf finalFeatures.security {
      # Enable GPG and SSH by default
      programs.gpg.enable = lib.mkDefault true;
      programs.ssh = {
        enable = lib.mkDefault true;
        # Disable default config to avoid future deprecation warning
        enableDefaultConfig = false;
      };
    })

    # Platform-specific overrides
    platformOverrides
  ];
}
