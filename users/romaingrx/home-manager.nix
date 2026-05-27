{ pkgs, ... }:
{
  imports = [
    ../../modules/home
    ../../modules/nvim.nix
    ./secrets.nix
    ./gpg.nix
    ./home-manager-nixos.nix
    ./home-manager-darwin.nix
    ./rust.nix
  ];

  programs.git.signing = {
    key = "383E2222E1BEFDAD";
    signByDefault = true;
  };

  programs.git.settings = {
    user.name = "Romain Graux";
    user.email = "48758915+romaingrx@users.noreply.github.com";
    commit.gpgsign = true;
  };

  home.packages = with pkgs; [
    tor
    brave
    # claude-code # Install it manually to keep it up-to-date
  ];
}
