{ pkgs, ... }:
{
  enable = true;
  package = pkgs.openssh;
  includes = [ "~/.ssh/config.local" ];
  matchBlocks = {
    "github.com" = {
      user = "git";
      identityFile = "~/.ssh/github";
      addKeysToAgent = "yes";
    };
  };
  extraConfig =
    ''
      # Keep connections alive
      ServerAliveInterval 60
      ServerAliveCountMax 2
    ''
    + pkgs.lib.optionalString pkgs.stdenv.isDarwin ''
      IgnoreUnknown UseKeychain
      AddKeysToAgent yes
      UseKeychain yes
    '';
}
