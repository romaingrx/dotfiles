{ ... }:
{
  homebrew = {
    enable = true;
    global = {
      brewfile = true;
      # The lockfiles option is removed completely as it's causing issues
    };
    onActivation = {
      cleanup = "zap"; # Remove non declared casks
      autoUpdate = false;
      upgrade = false;
      extraFlags = [ "--force" ];
    };

    # Homebrew permissions
    masApps = {
      "harvest" = 506189836;
    }; # Specify Mac App Store apps here if needed
    taps = [ ]; # Specify additional taps if needed

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
      "docker" # Docker Desktop
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
      # Personal brews
      "awscli"
      "yt-dlp"
      "meetingbar"
    ];
  };
}
