{ pkgs, ... }:
{
  imports = [
    ./programs/agent-skills.nix
    ./programs/alacritty.nix
    ./programs/borders.nix
    ./programs/claude-code.nix
    ./programs/hunk.nix
    ./programs/hypr.nix
    ./programs/rofi.nix
    ./programs/sketchybar.nix
    ./programs/tmux.nix
    ./programs/waybar.nix
    ./programs/zsh.nix
  ];

  programs = {
    git = import ./programs/git.nix { };
    ssh = import ./programs/ssh.nix { inherit pkgs; };
  };
}
