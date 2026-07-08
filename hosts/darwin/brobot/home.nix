{ pkgs, ... }:
{
  # brobot-only CLI packages (auto-imported by mkSystem when present).
  home.packages = with pkgs; [
    ffmpeg
    azure-cli
  ];

}
