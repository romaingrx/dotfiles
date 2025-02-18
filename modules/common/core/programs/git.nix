{ ... }: {
  enable = true;
  userName = "Romain Graux";
  userEmail = "48758915+romaingrx@users.noreply.github.com";

  # Add GPG signing
  signing = {
    key =
      null; # Will use the first secret key available that matches the user email
    signByDefault = true;
  };

  extraConfig = {
    commit.gpgsign = true;
    safe.directory = "*";
  };
}
