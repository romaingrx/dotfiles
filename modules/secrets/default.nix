{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.mySecrets;
in
{
  options.mySecrets = {
    enable = lib.mkEnableOption "sops secrets management";

    # Global settings
    ageKeyFile = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
      description = "Path to age key file";
    };

    defaultSopsFile = lib.mkOption {
      type = lib.types.path;
      description = "Default sops file for secrets";
    };

    # User secrets
    userSecrets = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            path = lib.mkOption {
              type = lib.types.str;
              description = "Target path for the secret";
            };

            mode = lib.mkOption {
              type = lib.types.str;
              default = "0600";
              description = "File mode for the secret";
            };

            owner = lib.mkOption {
              type = lib.types.str;
              default = config.home.username;
              description = "Owner of the secret file";
            };

            sopsFile = lib.mkOption {
              type = lib.types.path;
              default = cfg.defaultSopsFile;
              description = "Sops file containing this secret";
            };
          };
        }
      );
      default = { };
      description = "User-specific secrets configuration";
    };

    # Template configurations
    templates = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            content = lib.mkOption {
              type = lib.types.str;
              description = "Template content with placeholders";
            };

            path = lib.mkOption {
              type = lib.types.str;
              description = "Target path for the template";
            };

            mode = lib.mkOption {
              type = lib.types.str;
              default = "0644";
              description = "File mode for the template";
            };

            owner = lib.mkOption {
              type = lib.types.str;
              default = config.home.username;
              description = "Owner of the template file";
            };
          };
        }
      );
      default = { };
      description = "Template configurations";
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      # Age configuration
      age.keyFile = cfg.ageKeyFile;

      # Default sops file
      defaultSopsFile = cfg.defaultSopsFile;

      # User secrets
      secrets = lib.mapAttrs (name: secretCfg: {
        path = secretCfg.path;
        mode = secretCfg.mode;
        owner = secretCfg.owner;
        sopsFile = secretCfg.sopsFile;
      }) cfg.userSecrets;

      # Templates
      templates = lib.mapAttrs (name: templateCfg: {
        content = templateCfg.content;
        path = templateCfg.path;
        mode = templateCfg.mode;
        owner = templateCfg.owner;
      }) cfg.templates;
    };
  };
}
