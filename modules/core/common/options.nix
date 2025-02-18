{ lib, ... }: {
  options.home.github.gpg = {
    key = lib.mkOption {
      type = lib.types.str;
      description = "GitHub GPG key ID";
    };
    email = lib.mkOption {
      type = lib.types.str;
      description = "GitHub email address";
    };
  };
}
