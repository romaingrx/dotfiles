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
    pkgs.jujutsu
    master.claude-code
  ];

  programs.git.includes = [ { path = "~/.config/git/work.gitconfig"; } ];
}
