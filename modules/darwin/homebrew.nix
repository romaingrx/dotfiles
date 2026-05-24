_: {
  homebrew = {
    enable = true;
    global = { };
    onActivation = {
      cleanup = "uninstall";
      autoUpdate = false;
      upgrade = false;
    };

    masApps = { };
    taps = [ ];

    casks = [
      "font-fira-code-nerd-font" # Needed for alacritty
      "font-sf-pro"
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
