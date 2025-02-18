{ pkgs, ... }: {
  programs.gpg = {
    enable = true;
    settings = { trust-model = "tofu+pgp"; };
    # Enable gpg-agent with proper pinentry program
    mutableKeys = false;
    mutableTrust = false;

    # Configure gpg-agent
    scdaemonSettings = { disable-ccid = true; };

    publicKeys = [{ source = ./pubkeys/github.asc; }];
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentryPackage = pkgs.pinentry-curses;
    defaultCacheTtl = 3600;
    maxCacheTtl = 7200;
  };
}
