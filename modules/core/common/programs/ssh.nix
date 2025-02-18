{ pkgs, ... }: {
  enable = true;
  forwardAgent = true;
  package = pkgs.openssh;
  addKeysToAgent = "confirm";
  matchBlocks = {
    "github.com" = {
      user = "git";
      identityFile = "~/.ssh/github";
    };
  };
  extraConfig = ''
    # Keep connections alive
    ServerAliveInterval 60
    ServerAliveCountMax 2
    ${pkgs.lib.optionalString pkgs.stdenv.isDarwin "UseKeychain yes"}
  '';
}
