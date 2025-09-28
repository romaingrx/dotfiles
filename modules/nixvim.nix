{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.neve;
in
{
  options.programs.neve = {
    enable = lib.mkEnableOption "Neovim configured with Neve (Nixvim-based config)";

    # Configuration options for different features
    bufferlines.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable bufferline configuration";
    };

    colorschemes.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable colorscheme configuration";
    };

    completion.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable completion configuration";
    };

    dap.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable DAP (debug adapter protocol) configuration";
    };

    filetrees.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable file tree configuration";
    };

    git.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable git-related plugins";
    };

    languages.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable language-specific configurations";
    };

    lsp.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable LSP (Language Server Protocol) configuration";
    };

    none-ls.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable none-ls configuration";
    };

    pluginmanagers.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable plugin manager configuration";
    };

    sets.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable sets configuration";
    };

    snippets.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable snippets configuration";
    };

    statusline.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable statusline configuration";
    };

    telescope.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable telescope configuration";
    };

    ui.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable UI-related configurations";
    };

    utils.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable utility plugins";
    };
  };

  config = lib.mkIf cfg.enable {
    # Configure nixvim with our neve configuration
    programs.nixvim = {
      enable = true;

      # Import our neve configuration with user overrides
      imports = [
        (import ./nixvim/config)
      ];

      # Override the default enables with user configuration
      bufferlines.enable = cfg.bufferlines.enable;
      colorschemes.enable = cfg.colorschemes.enable;
      completion.enable = cfg.completion.enable;
      dap.enable = cfg.dap.enable;
      filetrees.enable = cfg.filetrees.enable;
      git.enable = cfg.git.enable;
      languages.enable = cfg.languages.enable;
      lsp.enable = cfg.lsp.enable;
      none-ls.enable = cfg.none-ls.enable;
      pluginmanagers.enable = cfg.pluginmanagers.enable;
      sets.enable = cfg.sets.enable;
      snippets.enable = cfg.snippets.enable;
      statusline.enable = cfg.statusline.enable;
      telescope.enable = cfg.telescope.enable;
      ui.enable = cfg.ui.enable;
      utils.enable = cfg.utils.enable;
    };
  };
}
