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
      "font-fira-code-nerd-font" # Needed for alacritty
      "anaconda"
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