{ pkgs, ... }: {
  home.packages = with pkgs; [
    docker
    docker-compose
    ffmpeg

    ## Python
    uv

    ## Node / JS
    bun
    pnpm

    ## MacOS only
    raycast
    alacritty
  ];
}
