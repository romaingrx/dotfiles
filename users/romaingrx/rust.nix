{ pkgs, inputs, ... }:

let
  # Using the stable toolchain from Fenix
  rustToolchain = inputs.fenix.packages.${pkgs.system}.stable.toolchain;
  # rust-analyzer = inputs.fenix.packages.${pkgs.system}.rust-analyzer;
in {
  home.packages = [
    rustToolchain # Provides rustc, cargo, rustfmt, clippy
    # rust-analyzer # LSP server for Rust

    # You can add other cargo tools here if needed, for example:
    # pkgs.cargo-watch
    # pkgs.cargo-edit
  ];

  # Home Manager should automatically add the necessary binaries to your PATH.

  # If RUST_SRC_PATH needs to be set explicitly for some reason:
  # home.sessionVariables = {
  #   RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
  # };
}
