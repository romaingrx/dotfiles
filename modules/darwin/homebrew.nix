_: {
  homebrew = {
    enable = true;
    global = { };
    onActivation = {
      cleanup = "uninstall";
      autoUpdate = false;
      upgrade = false;
    };

    masApps = {
      Tailscale = 1475387142;
    };
    taps = [ ];

    casks = [
      # FiraCode Nerd Font is installed from the theme contract via
      # modules/fonts.nix (pkgs.nerd-fonts.fira-code), so no cask is needed.
      "sf-symbols"
      "firefox"
      "duckduckgo"
      "wifiman"
      "anytype"
      "spotify"
      "avogadro"
      "onedrive"
    ];
    brews = [
      "watch"
      "ffmpeg"
      "mactop"
      "libpq"
      "yt-dlp"
      "awscli"
      "mas"
    ];
  };
}
