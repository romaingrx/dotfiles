{ config, lib, ... }:
let
  cfg = config.romaingrx.theme;
  theme = import ../../../lib/theme { };
in
{
  options.romaingrx.theme = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable the centralized romaingrx theme contract.";
    };

    defaultAppearance = lib.mkOption {
      type = lib.types.enum theme.appearanceNames;
      default = "dark";
      description = "The appearance used for first-run theme bootstrap.";
    };

    generatedRoot = lib.mkOption {
      type = lib.types.str;
      default = ".config/romaingrx/theme/generated";
      description = "Home-relative directory for generated theme artifacts.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = builtins.hasAttr cfg.defaultAppearance theme.appearances;
        message = "romaingrx.theme.defaultAppearance must be one of: ${lib.concatStringsSep ", " theme.appearanceNames}";
      }
    ];
  };
}
