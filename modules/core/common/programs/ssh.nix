{ pkgs, ... }: {
  enable = true;
  forwardAgent = true;
  addKeysToAgent = "1h";
  matchBlocks = {
    "github.com" = {
      user = "git";
      identityFile = "~/.ssh/github";
    };
  };
  extraConfig = ''
    AddKeysToAgent yes
    ${pkgs.lib.optionalString pkgs.stdenv.isDarwin "UseKeychain yes"}
  '';
}
