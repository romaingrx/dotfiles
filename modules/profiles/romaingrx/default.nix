{ pkgs, config, ... }: {
  imports = [ ../../../modules/core/common ];

  home = {
    stateVersion = "24.05";
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
    packages = with pkgs; [ openbabel zoom-us ];
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
