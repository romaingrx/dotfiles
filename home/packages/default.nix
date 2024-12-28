{ pkgs, ... }: {
  home.packages = with pkgs; [
    docker
    docker-compose
    ffmpeg
    tor

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
