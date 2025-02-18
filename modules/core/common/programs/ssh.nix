{ ... }: {
  enable = true;
  matchBlocks = {
    "github.com" = {
      user = "git";
      identityFile = "~/.ssh/github";
    };
  };
  extraConfig = ''
    UseKeychain yes
    AddKeysToAgent yes
  '';
}
