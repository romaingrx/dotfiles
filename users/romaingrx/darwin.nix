{ pkgs, ... }: {
  users.users.romaingrx = {
    home = "/Users/romaingrx";
    shell = pkgs.zsh;
  };
}
