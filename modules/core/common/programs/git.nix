{
  enable = true;
  userName = "Romain Graux";
  userEmail = "48758915+romaingrx@users.noreply.github.com";

  # Add GPG signing
  signing = {
    key = null; # Default key based on email and name
    signByDefault = true;
  };

  extraConfig = {
    commit.gpgsign = true;
    safe.directory = "*";
  };
}