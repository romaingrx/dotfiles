{ pkgs, ... }: {
  enable = true;
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
