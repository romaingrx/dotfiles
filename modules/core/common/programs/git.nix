{
  enable = true;
  userName = "Romain Graux";
  userEmail = "48758915+romaingrx@users.noreply.github.com";

  # Add GPG signing
  signing = {
    key = "EE706544613BE505"; # GitHub-specific GPG key
    signByDefault = true;
  };

  extraConfig = {
    commit.gpgsign = true;
    safe.directory = "*";
  };
}
