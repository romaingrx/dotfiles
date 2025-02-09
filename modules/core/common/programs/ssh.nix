{ config, ... }: {
  enable = true;
  matchBlocks = {
    "github.com" = {
      user = "git";
      identityFile = if config.home.username == "romaingrx" then
        "~/.ssh/github"
      else
        "~/.ssh/github_lcmd";
    };
    "dipsy" = {
      user = "romaingrx";
      hostname = "10.42.0.4";
      identityFile = "~/.ssh/dipsy";
    };
  };
  extraConfig = ''
    UseKeychain yes
    AddKeysToAgent yes
  '';
}
