{ pkgs, ... }: {
  imports = [ ../../modules/core/common ];

  home = {
    stateVersion = "24.11";
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
    packages = with pkgs; [ ollama tor mitmproxy ];
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
