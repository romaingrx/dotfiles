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

    runtimeRoot = lib.mkOption {
      type = lib.types.str;
      default = ".local/state/theme";
      description = "Home-relative directory for runtime theme state and active symlinks.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = builtins.hasAttr cfg.defaultAppearance theme.appearances;
        message = "romaingrx.theme.defaultAppearance must be one of: ${lib.concatStringsSep ", " theme.appearanceNames}";
      }
    ];

    home.activation.romaingrxThemeBootstrap = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      generated_root="${config.home.homeDirectory}/${cfg.generatedRoot}"
      runtime_root="${config.home.homeDirectory}/${cfg.runtimeRoot}"
      default_target="$generated_root/${cfg.defaultAppearance}"
      current_link="$runtime_root/current"
      appearance_file="$runtime_root/appearance"

      if [ ! -d "$default_target" ]; then
        echo "Missing default generated theme: $default_target" >&2
        exit 1
      fi

      mkdir -p "$runtime_root"

      if [ ! -e "$current_link" ]; then
        tmp_link="$runtime_root/.current.tmp.$$"
        rm -f "$tmp_link"
        ln -s "$default_target" "$tmp_link"

        if [ -e "$current_link" ] && [ ! -L "$current_link" ]; then
          echo "Refusing to replace non-symlink theme current path: $current_link" >&2
          rm -f "$tmp_link"
          exit 1
        fi

        rm -f "$current_link"
        mv "$tmp_link" "$current_link"
      fi

      if [ ! -f "$appearance_file" ]; then
        printf '%s\n' "${cfg.defaultAppearance}" > "$appearance_file"
      fi
    '';
  };
}
