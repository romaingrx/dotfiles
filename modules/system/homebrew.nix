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
    ];
    onActivation.cleanup = "zap"; # Remove non declared casks
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };
} 