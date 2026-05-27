{ pkgs, ... }:
{
  enable = true;
  package = pkgs.openssh;
  enableDefaultConfig = false;
  includes = [ "~/.ssh/config.local" ];
  settings = {
    "github.com" = {
      User = "git";
      HostName = "ssh.github.com";
      Port = 443;
      IdentityFile = "~/.ssh/github";
      AddKeysToAgent = "yes";
    };
    "*" = {
      ServerAliveInterval = "60";
      ServerAliveCountMax = "2";
    }
    // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
      IgnoreUnknown = "UseKeychain";
      AddKeysToAgent = "yes";
      UseKeychain = "yes";
    };
  };
}
