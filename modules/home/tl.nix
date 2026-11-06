{
  config,
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
  options.dotfiles.tl.enable = lib.mkEnableOption "Trajectory Labs work tooling";

  config = lib.mkIf config.dotfiles.tl.enable {
    home.packages = [
      pkgs.awscli2
      pkgs.jujutsu
      master.claude-code
    ];

    programs.git.includes = [ { path = "~/.config/git/work.gitconfig"; } ];
  };
}
