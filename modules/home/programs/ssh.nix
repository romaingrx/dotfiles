{ pkgs, ... }:
{
  enable = true;
  package = pkgs.openssh;
  enableDefaultConfig = false;
  includes = [ "~/.ssh/config.local" ];
  matchBlocks = {
    "github.com" = {
      user = "git";
      identityFile = "~/.ssh/github";
      extraOptions.AddKeysToAgent = "yes";
    };
    "*" = {
      extraOptions =
        {
          ServerAliveInterval = "60";
          ServerAliveCountMax = "2";
        }
        // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
          IgnoreUnknown = "UseKeychain";
          AddKeysToAgent = "yes";
          UseKeychain = "yes";
        };
    };
  };
}
