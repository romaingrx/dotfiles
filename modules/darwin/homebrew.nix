{ ... }:
{
  homebrew = {
    enable = true;
    global = { };
    onActivation = {
      cleanup = "none"; # Remove non declared casks
      autoUpdate = false;
      upgrade = false;
      extraFlags = [ "--force" ];
    };

    # Homebrew permissions
    masApps = { };
    taps = [ ];

    casks = [
      "font-fira-code-nerd-font" # Needed for alacritty
      "font-sf-pro"
      "sf-symbols"
      "firefox"
      "duckduckgo"
      "displaylink"
      "wifiman"
      "avogadro"
      "cursor"
      "airtable"
      "anytype"
      "spotify"
    ];
    brews = [
      "watch"
      "ffmpeg"
      "mactop"
      "lightgbm"
      "libpq"
      "yt-dlp"
    ];
  };
}
