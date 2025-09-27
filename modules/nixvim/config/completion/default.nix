{ lib, config, ... }: {
  imports = [
    ./cmp.nix
    ./codeium.nix
    # ./copilot.nix  # Temporarily disabled due to Node.js 18.x EOL issues
    ./lspkind.nix
  ];

  options = {
    completion.enable = lib.mkEnableOption "Enable completion module";
  };
  config = lib.mkIf config.completion.enable {
    cmp.enable = lib.mkDefault true;
    codeium.enable = lib.mkDefault false;
    # copilot.enable = lib.mkDefault false;  # Module disabled above
    lspkind.enable = lib.mkDefault true;
  };
}
