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
    signal-desktop
    obsidian
    gnupg
    slack
    git-lfs
    libpqxx # PostgreSql C++ client
    minikube # When starting minikube with qemu, we need to specify the path as :  --qemu-firmware-path=/run/current-system/.../edk2-aarch64-code.fd 
    kubectl # Kubectl should be a dependency of minikube so might not be needed
    qemu # Used as the hypervisor for minikube
    pre-commit
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
