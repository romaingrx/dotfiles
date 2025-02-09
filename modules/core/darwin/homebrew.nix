{ ... }: {
  homebrew = {
    enable = true;
    global = {
      brewfile = true;
      lockfiles = false;  # Disable lockfiles to prevent permission issues
    };
    onActivation = {
      cleanup = "zap"; # Remove non declared casks
      autoUpdate = true;
      upgrade = true;
      extraFlags = [
        "--force"
      ];
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
    ];
    brews = [
      "bitwarden-cli"
      "ffmpeg"
      "mactop"
      "lightgbm"
      "libpq"
    ];
  };
} 
