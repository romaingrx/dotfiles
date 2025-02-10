{ pkgs, ... }: {
  home.packages = with pkgs; [
    nixfmt-classic
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
    minikube # When starting minikube with qemu, we need to specify the path as :  --qemu-firmware-path=/run/current-system/.../edk2-aarch64-code.fd
    kubectl # Kubectl should be a dependency of minikube so might not be needed
    qemu # Used as the hypervisor for minikube
    pre-commit
    wrangler
  ];
}
