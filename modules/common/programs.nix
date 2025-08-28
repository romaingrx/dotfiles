{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myConfig.programs;
in
{
  options.myConfig.programs = {
    enable = lib.mkEnableOption "common programs";
  };

  config = lib.mkIf cfg.enable {
    # Import the exact same program configurations that were working before
    programs = {
      git = import ../core/common/programs/git.nix { inherit config; };
      zsh = import ../core/common/programs/zsh.nix { inherit config pkgs; };
      fzf = {
        enable = true;
        enableZshIntegration = true;
      };
      ssh = import ../core/common/programs/ssh.nix { inherit pkgs; };
      gpg = import ../core/common/programs/gpg.nix;
      alacritty = import ../core/common/programs/alacritty.nix { inherit pkgs; };
      tmux = import ../core/common/programs/tmux.nix { inherit pkgs; };
    };
  };
}
