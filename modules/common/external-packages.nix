{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myConfig.externalPackages;
in
{
  options.myConfig.externalPackages = {
    enable = lib.mkEnableOption "external packages (Homebrew, etc.)";

    homebrew = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Homebrew package manager";
      };

      # Package categories
      browsers.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable browser applications";
      };

      productivity.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable productivity applications";
      };

      development.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable development applications";
      };

      media.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable media applications";
      };

      extraCasks = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Additional Homebrew casks";
      };

      extraBrews = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Additional Homebrew formulas";
      };
    };
  };

  config = lib.mkIf (cfg.enable && cfg.homebrew.enable && pkgs.stdenv.isDarwin) {
    homebrew = {
      enable = true;
      global = {
        brewfile = true;
      };
      onActivation = {
        cleanup = "zap";
        autoUpdate = false;
        upgrade = false;
        extraFlags = [ "--force" ];
      };

      # Mac App Store apps
      masApps = {
        "harvest" = 506189836;
      };

      casks = lib.flatten [
        # Browser applications
        (lib.optionals cfg.homebrew.browsers.enable [
          "firefox"
          "duckduckgo"
        ])

        # Productivity applications
        (lib.optionals cfg.homebrew.productivity.enable [
          "spotify"
          "font-fira-code-nerd-font"
          "font-sf-pro"
          "sf-symbols"
          "wifiman"
          "airtable"
          "anytype"
          "onedrive"
          "mattermost"
        ])

        # Development applications
        (lib.optionals cfg.homebrew.development.enable [
          "cursor"
          "docker"
          "anaconda"
          "displaylink"
        ])

        # Media applications
        (lib.optionals cfg.homebrew.media.enable [ "avogadro" ])

        cfg.homebrew.extraCasks
      ];

      brews = lib.flatten [
        # Essential command-line tools
        [
          "watch"
          "ffmpeg"
          "mactop"
          "lightgbm"
          "libpq"
          "awscli"
          "yt-dlp"
        ]

        cfg.homebrew.extraBrews
      ];
    };
  };
}
