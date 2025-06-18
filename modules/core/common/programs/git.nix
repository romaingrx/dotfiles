{ config, ... }: {
  enable = true;
  userName = "Romain Graux";
  userEmail = config.home.github.gpg.email;

  # Add GPG signing
  signing = {
    key = config.home.github.gpg.key;
    signByDefault = true;
  };

  aliases = {
    a = "add .";
    co = "checkout";
    cob = "checkout -b";
    br =
      "branch --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:green)(%(committerdate:relative)) [%(authorname)]' --sort=-committerdate";
    lg = ''
      log --pretty=format:"%C(magenta)%h%Creset -%C(red)%d%Creset %s %C(dim green)(%cr) [%an]" --abbrev-commit -30'';
  };

  extraConfig = {
    commit.gpgsign = true;
    safe.directory = "*";
  };
}
