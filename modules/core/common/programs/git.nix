{ config, ... }:
{
  enable = true;

  # Add GPG signing
  signing = {
    key = config.home.github.gpg.key;
    signByDefault = true;
  };

  settings = {
    user = {
      name = "Romain Graux";
      email = config.home.github.gpg.email;
    };

    alias = {
      a = "add .";
      co = "checkout";
      cob = "checkout -b";
      br = "branch --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:green)(%(committerdate:relative)) [%(authorname)]' --sort=-committerdate";
      lg = ''log --pretty=format:"%C(magenta)%h%Creset -%C(red)%d%Creset %s %C(dim green)(%cr) [%an]" --abbrev-commit -30'';
    };

    commit.gpgsign = true;
    safe.directory = "*";

    # Performance optimizations
    core.preloadindex = true;
    core.fscache = true;

    # Garbage collection settings
    gc.auto = 256;
  };
}
