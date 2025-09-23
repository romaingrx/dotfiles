{ pkgs, ... }: {
  home.packages = with pkgs; [
    nixfmt-rfc-style
    nil # Nix LSP
    sops
    docker
    docker-compose
    ffmpeg
    uv
    bun
    pnpm
    alacritty
    # signal-desktop  # Not available on ARM macOS
    obsidian
    gnupg
    slack
    git-lfs
    minikube # When starting minikube with qemu, we need to specify the path as :  --qemu-firmware-path=/run/current-system/.../edk2-aarch64-code.fd
    kubectl # Kubectl should be a dependency of minikube so might not be needed
    kustomize
    kubeseal
    kubernetes-helm
    qemu # Used as the hypervisor for minikube
    pre-commit
    nodejs_23
    # cargo
    # rustc
    # rustfmt
    # rust-analyzer
  ];
}
