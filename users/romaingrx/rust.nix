{ pkgs, ... }:
{
  home.packages = with pkgs; [
    rustc
    cargo
    clippy
    rustfmt
  ];

  home.sessionVariables.RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
}
