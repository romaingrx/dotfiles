{pkgs, config, ...}: 

let
  # Common packages for both personal and work profiles
  commonPackages = with pkgs; [
    docker
    docker-compose
    ffmpeg
    uv
    kubectl
    bun
    pnpm
    raycast
    alacritty
    signal-desktop
    obsidian
    gnupg
    slack
    git-lfs
    libpqxx # PostgreSql C++ client
  ];

  # TODO : change this and accept extra packages from inputs
  # Personal-only packages
  personalPackages = with pkgs; [
    ollama
    tor
    mitmproxy
  ];

  # Work-only packages
  workPackages = with pkgs; [
    openbabel
    zoom-us
  ];

  # Add work specific packages on linux machine
  linuxWorkPackages = with pkgs; [
    onedrive
    mattermost-desktop
  ];

  # Determine which role-specific packages to include
  roleSpecificPackages = if config.home.username == "romaingrx"
    then personalPackages
    else workPackages;

  # Add Linux-specific packages if on Linux
  platformSpecificPackages = if pkgs.stdenv.isLinux
    then linuxWorkPackages
    else [];

in {
  home.packages = commonPackages ++ roleSpecificPackages ++ platformSpecificPackages;
}
