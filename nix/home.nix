{pkgs, ...}: {
  home.stateVersion = "24.05";  # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment
    # hello
    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides:
    # # discord.override {
    # #   # Disable automatic updates since this is essentially a wrapper
    # #   withVencord = true;
    # # }
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/bashrc' in
    # # the Nix store and symlink it from '.bashrc' in your home directory.
    # ".bashrc".source = dotfiles/bashrc;
  };

  # You can also manage environment variables but you will need to manually
  # source
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/romaingrx/etc/profile.d/hm-session-vars.sh
  #
  # if you don't want to manage your shell through Home Manager.
  home.sessionVariables = {
    EDITOR = "nvim";
    TEST = "test";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
} 