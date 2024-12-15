{
  enable = true;
  enableCompletion = true;
  autosuggestion.enable = true;
  syntaxHighlighting.enable = true;

  oh-my-zsh = {
    enable = true;
    plugins = [
      "git"
      "docker"
      "command-not-found"
      "sudo"
    ];
    theme = "robbyrussell";
  };

  shellAliases = {
    ll = "ls -l";
    la = "ls -la";
    # update = "sudo nixos-rebuild switch";
    ".." = "cd ..";
    "..." = "cd ../..";
  };

  history = {
    size = 10000;
    path = "$HOME/.zsh_history";
    ignoreDups = true;
    share = true;
  };

  initExtra = ''
    # Fix for arrow key history search
    bindkey "''${key[Up]}" up-line-or-search
    bindkey "''${key[Down]}" down-line-or-search

    # Better directory navigation
    setopt AUTO_CD
    setopt AUTO_PUSHD
    setopt PUSHD_IGNORE_DUPS
    setopt PUSHD_MINUS
  '';
}
