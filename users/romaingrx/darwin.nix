{ pkgs, ... }: {
  users.users.romaingrx = {
    home = "/Users/romaingrx";
    shell = pkgs.zsh;
  };

  fonts.packages = with pkgs; [ nerd-fonts.fira-code ];

  
}
