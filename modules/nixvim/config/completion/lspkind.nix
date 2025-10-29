{ lib, config, ... }:
{
  options = {
    lspkind.enable = lib.mkEnableOption "Enable lspkind module";
  };
  config = lib.mkIf config.lspkind.enable {

    plugins.lspkind = {
      enable = true;
      settings = {
        symbol_map = {
          Copilot = "";
        };
        maxwidth = 50;
        ellipsis_char = "...";
      };
    };
  };
}
