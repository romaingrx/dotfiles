{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  master = import inputs.nixpkgs-master {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfreePredicate = pkg: lib.getName pkg == "claude-code";
  };
in
{
  home.packages = [
    pkgs.awscli2
    pkgs.bun
    pkgs.jujutsu
    pkgs.sentry-cli
    (pkgs.callPackage ../../pkgs/datadog-pup.nix { })
    master.claude-code
  ];

  programs.git.includes = [ { path = "~/.config/git/work.gitconfig"; } ];
}
