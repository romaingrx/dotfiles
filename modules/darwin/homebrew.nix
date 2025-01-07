{...}: {
  # TODO : change this and accept extra brews and casks from inputs

  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap"; # Remove non declared casks
      autoUpdate = true;
      upgrade = true;
      extraFlags = [
        "--force"
      ];
    };

    # Homebrew permissions
    masApps = {}; # Specify Mac App Store apps here if needed
    taps = [];    # Specify additional taps if needed

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
      "avogadro"
      "wifiman"
      "onedrive"
    ];
    brews = [
      "bitwarden-cli"
      "ffmpeg"
    ];
  };
} 