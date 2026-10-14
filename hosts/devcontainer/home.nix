# Standalone home-manager profile for throwaway dev containers.
{
  config,
  pkgs,
  dotfilesPath,
  ...
}:
{
  imports = [
    ../../modules/nvim.nix
    ../../modules/home/programs/agent-skills.nix
    ../../modules/home/programs/git.nix
    ../../modules/home/programs/zsh.nix
  ];

  home = {
    stateVersion = "24.11";
    packages = with pkgs; [
      lazygit
      tmux
    ];
    file.".config/tmux".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/config/tmux";
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };

  programs.home-manager.enable = true;
}
