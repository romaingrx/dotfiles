{...}: {
  homebrew = {
    enable = true;
    casks = [
      "firefox"
      "cursor"
      "duckduckgo"
    ];
    onActivation.cleanup = "zap"; # Remove non declared casks
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };
} 