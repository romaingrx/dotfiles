{
  enable = true;
  userName = "Romain Graux";
  userEmail = "48758915+romaingrx@users.noreply.github.com";

  # Add GPG signing
  signing = {
    key = "C52A01AE82206AB2"; # Default key
    signByDefault = true;
  };

  extraConfig = {
    commit.gpgsign = true;
  };
}
