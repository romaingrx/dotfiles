{ ... }:
{
  enable = true;

  settings = {
    alias = {
      a = "add .";
      co = "checkout";
      cob = "checkout -b";
      br = "branch --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:green)(%(committerdate:relative)) [%(authorname)]' --sort=-committerdate";
      lg = ''log --pretty=format:"%C(magenta)%h%Creset -%C(red)%d%Creset %s %C(dim green)(%cr) [%an]" --abbrev-commit -30'';
    };

    safe.directory = "*";
    core.preloadindex = true;
    core.fscache = true;
    gc.auto = 256;
  };
}
