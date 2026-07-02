{ pkgs, ... }:
{
  # brobot-only CLI packages (auto-imported by mkSystem when present).
  home.packages = [ pkgs.ffmpeg ];
}
