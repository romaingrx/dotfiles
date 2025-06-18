{ ... }: {
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
      "firefox"
      "cursor"
      "duckduckgo"
      "displaylink"
      "spotify"
      "bitwarden"
      "docker" # Docker Desktop
      "anaconda"
      "font-fira-code-nerd-font" # Needed for alacritty
      "font-sf-pro"
      "sf-symbols"
      "wifiman"
      "airtable"
      "anytype"
      # Work related casks
      "avogadro"
      "onedrive"
      "mattermost"
    ];
    brews = [
      "watch"
      "bitwarden-cli"
      "ffmpeg"
      "mactop"
      "lightgbm"
      "libpq"
      # Personal brews
      "awscli"
      "yt-dlp"
    ];
  };
}
