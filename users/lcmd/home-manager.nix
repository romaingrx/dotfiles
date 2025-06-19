{ pkgs, inputs, ... }: {
  imports = [ ../../modules/common ];

  # Enable the new configuration options
  myConfig = {
    common.enable = true;

    # User packages (Home Manager)
    packages = {
      enable = true;
      core.enable = true;
      development.enable = true; # Enable basic dev tools for lcmd
      productivity.enable = true;
      media.enable = true;
      extraPackages = with pkgs; [
        inputs.romaingrx-nixvim.packages.${system}.default
        openbabel
        zoom-us
        ansible
      ];
    };

    programs.enable = true;

    # System packages (environment.systemPackages) - enable basic dev tools
    systemPackages = {
      enable = true;
      core.enable = true;
      development.enable = true; # Enable basic dev system packages for lcmd
    };

    # External packages (Homebrew) now configured at system level via modules/darwin/
  };

  # Compatibility configuration for original git.nix
  home.github.gpg = {
    key = "44FDF809CFE3A012";
    email = "48758915+romaingrx@users.noreply.github.com";
  };
}
