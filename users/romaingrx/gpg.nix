{ pkgs, ... }:
let
  pinentryPackage = if pkgs.stdenv.isDarwin then pkgs.pinentry_mac else pkgs.pinentry-curses;
in
{
  programs.gpg = {
    enable = true;
    settings = {
      trust-model = "tofu+pgp";
    };
    # Disable automatic key management to prevent import errors during activation
    mutableKeys = true;
    mutableTrust = true;

    # Configure gpg-agent
    scdaemonSettings = {
      disable-ccid = true;
    };

    # Comment out the public keys to prevent automatic import during activation
    # publicKeys = [{ source = ./pubkeys/github.asc; }];
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    # Use OS specific pinentry
    pinentryPackage = pinentryPackage;
    defaultCacheTtl = 28800;
    maxCacheTtl = 86400;
    # Configure gpg-agent to use the TTY
    extraConfig = ''
      allow-loopback-pinentry
      allow-emacs-pinentry
      allow-preset-passphrase
      default-cache-ttl-ssh 28800
      max-cache-ttl-ssh 86400
    '';
  };

  # Add required environment variables
  home.sessionVariables = {
    GPG_TTY = "$(tty)";
    # Remove PINENTRY_USER_DATA since we're using pinentry-curses
    SSH_AUTH_SOCK = "$(gpgconf --list-dirs agent-ssh-socket)";
  };
}
