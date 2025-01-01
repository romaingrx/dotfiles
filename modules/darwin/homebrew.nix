{...}: {
  homebrew = {
    enable = true;
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
    ];
    brews = [
      "bitwarden-cli"
      "ffmpeg"
    ];
    
    onActivation.cleanup = "zap"; # Remove non declared casks
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };
} 