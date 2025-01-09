{config, lib, ...}: 
let
  inherit (lib) mkOption types;
in {
  options = {
    local = {
      homebrew = {
        extraCasks = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Additional casks to install for this profile";
        };
        extraBrews = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Additional brews to install for this profile";
        };
        extraTaps = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Additional taps to install for this profile";
        };
        extraMasApps = mkOption {
          type = types.attrs;
          default = {};
          description = "Additional Mac App Store apps to install for this profile";
        };
      };
    };
  };
} 