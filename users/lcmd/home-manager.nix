{ ... }:
{ pkgs, ... }: {
  imports = [ ../../modules/core/common ../romaingrx/neovim.nix ];

  # State version
  home.packages = with pkgs; [ openbabel zoom-us just biome ];

  # Set GitHub GPG configuration values
  home.github.gpg = {
    key = "44FDF809CFE3A012";
    email = "48758915+romaingrx@users.noreply.github.com";
  };
}
