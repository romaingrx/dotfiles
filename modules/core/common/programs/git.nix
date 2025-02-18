{ config, ... }: {
  enable = true;
  userName = "Romain Graux";
  userEmail = config.home.github.gpg.email;

  # Add GPG signing
  signing = {
    key = config.home.github.gpg.key;
    signByDefault = true;
  };

  extraConfig = {
    commit.gpgsign = true;
    safe.directory = "*";
  };
}
