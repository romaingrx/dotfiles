{ pkgs, ... }: {
  home.packages = with pkgs; [
    nixfmt-classic
    nil # Nix LSP
    sops
    docker
    docker-compose
    ffmpeg
    uv
    bun
    pnpm
    alacritty
    signal-desktop
    obsidian
    gnupg
    slack
    git-lfs
    minikube # When starting minikube with qemu, we need to specify the path as :  --qemu-firmware-path=/run/current-system/.../edk2-aarch64-code.fd
    kubectl # Kubectl should be a dependency of minikube so might not be needed
    kustomize
    qemu # Used as the hypervisor for minikube
    pre-commit
    nodejs_23
  ];
}
