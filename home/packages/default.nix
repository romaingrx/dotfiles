{ pkgs, ... }:

let
  # mitmproxy-location is a script that takes care of setting up the certificates 
  # and the proxy location at launch time then cleans up after the proxy is closed
  mitmproxy-location = pkgs.writeShellApplication {
    name = "mitmproxy-location";
    runtimeInputs = with pkgs; [
      mitmproxy
      openssl
    ];
    text = builtins.readFile ./scripts/mitmproxy-location.sh;
  };
in
{
  home.packages = with pkgs; [
    docker
    docker-compose
    ffmpeg
    tor
    mitmproxy
    mitmproxy-location

    ## Apps
    obsidian
    signal-desktop

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
