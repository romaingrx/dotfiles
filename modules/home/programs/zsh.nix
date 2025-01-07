{ config, pkgs, ... }: {
  enable = true;
  enableCompletion = true;
  autosuggestion.enable = true;
  syntaxHighlighting.enable = true;

  plugins = with pkgs; [
    {
      name = "zsh-vi-mode";
      src = fetchFromGitHub {
        owner = "jeffreytse";
        repo = "zsh-vi-mode";
        rev = "v0.11.0";
        sha256 = "sha256-xbchXJTFWeABTwq6h4KWLh+EvydDrDzcY9AQVK65RS8=";
      };
    }
    {
      name = "zsh-syntax-highlighting";
      src = fetchFromGitHub {
        owner = "zsh-users";
        repo = "zsh-syntax-highlighting";
        rev = "0.6.0";
        sha256 = "sha256-hH4qrpSotxNB7zIT3u7qcog51yTQr5j5Lblq9ZsxuH4=";
      };
      file = "zsh-syntax-highlighting.zsh";
    }
  ];

  shellAliases = {
    ll = "ls -l";
    la = "ls -la";
    update = "nix run nix-darwin -- switch --flake /opt/dotfiles";
  };

  history = {
    size = 10000;
    path = "$HOME/.zsh_history";
    ignoreDups = true;
    share = true;
  };

  initExtra = ''
    # Initialize key array
    typeset -A key
    key[Up]=''${terminfo[kcuu1]}
    key[Down]=''${terminfo[kcud1]}

    # Fix for arrow key history search
    bindkey "^[[A" up-line-or-search
    bindkey "^[[B" down-line-or-search

    # Better directory navigation
    setopt AUTO_CD
    setopt AUTO_PUSHD
    setopt PUSHD_IGNORE_DUPS
    setopt PUSHD_MINUS

    # GPG configuration
    export GPG_TTY=$(tty)
    if [ -f "${config.home.homeDirectory}/.gpg-agent-info" ]; then
      . "${config.home.homeDirectory}/.gpg-agent-info"
      export GPG_AGENT_INFO
    fi
  '';
}
