{pkgs, config, ...}: 

let
  # Common packages for both personal and work profiles
  commonPackages = with pkgs; [
    docker
    docker-compose
    ffmpeg
    uv
    bun
    pnpm
    raycast
    alacritty
  ];

  # Personal-only packages
  personalPackages = with pkgs; [
    tor
    mitmproxy
    obsidian
    signal-desktop
  ];

  # Work-only packages
  workPackages = with pkgs; [
    # Add work-specific packages here
  ];

  # Determine which role-specific packages to include
  roleSpecificPackages = if config.home.username == "romaingrx"
    then personalPackages
    else workPackages;

in {
  home.packages = commonPackages ++ roleSpecificPackages;
}
