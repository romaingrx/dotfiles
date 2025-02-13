{ pkgs, ... }: {
  users.users.lcmd = {
    home = "/Users/lcmd";
    shell = pkgs.zsh;
  };
}
