{ pkgs, inputs, ... }: {
  imports = [ ../../modules/core/common ];

  # State version
  home.packages = with pkgs; [
    inputs.romaingrx-nixvim.packages.${system}.default
    openbabel
    zoom-us
    just
    biome
    ansible
  ];

  # Set GitHub GPG configuration values
  home.github.gpg = {
    key = "44FDF809CFE3A012";
    email = "48758915+romaingrx@users.noreply.github.com";
  };
}
