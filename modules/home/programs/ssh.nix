{ config, ... }: {
  enable = true;
  matchBlocks = {
    "github.com" = {
      user = "git";
      identityFile =
        if config.home.username == "romaingrx"
        then "~/.ssh/github"
        else "~/.ssh/github_lcmd";
    };
  };
  extraConfig = ''
    UseKeychain yes
    AddKeysToAgent yes
  '';
}
