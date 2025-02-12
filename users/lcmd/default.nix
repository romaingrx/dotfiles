{ pkgs, ... }: {
  imports = [ ../../modules/core/common ];

  # State version
  home = {
    stateVersion = "24.11";
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
    packages = with pkgs; [ openbabel zoom-us ];
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
