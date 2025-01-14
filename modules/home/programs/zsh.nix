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
    {
      name = "powerlevel10k";
      src = fetchFromGitHub {
        owner = "romkatv";
        repo = "powerlevel10k";
        rev = "v1.19.0";
        sha256 = "sha256-+hzjSbbrXr0w1rGHm6m2oZ6pfmD6UUDBfPd7uMg5l5c=";
      };
    }
    {
      name = "zsh-autosuggestions";
      src = fetchFromGitHub {
        owner = "zsh-users";
        repo = "zsh-autosuggestions";
        rev = "v0.7.0";
        sha256 = "sha256-KLUYpUu4DHRumQZ3w59m9aTW6TBKMCXl2UcKi4uMd7w=";
      };
    }
  ];

  shellAliases = {
    ll = "ls -l";
    la = "ls -la";
    update = "nix run nix-darwin -- switch --flake /opt/dotfiles";
    # Add some useful git aliases
    gs = "git status";
    gc = "git commit";
    gp = "git push";
    gl = "git pull";
  };

  history = {
    size = 10000;
    path = "$HOME/.zsh_history";
    ignoreDups = true;
    share = true;
    extended = true;  # Save timestamp
  };

  initExtra = ''
    # Load and configure powerlevel10k
    source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
    [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

    # Better directory navigation
    setopt AUTO_CD
    setopt AUTO_PUSHD
    setopt PUSHD_IGNORE_DUPS
    setopt PUSHD_MINUS

    # Command history improvements
    setopt HIST_EXPIRE_DUPS_FIRST
    setopt HIST_IGNORE_SPACE
    setopt HIST_VERIFY
    setopt SHARE_HISTORY

    # Better completion
    zstyle ':completion:*' menu select
    zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

    # Key bindings
    bindkey "^[[A" up-line-or-search
    bindkey "^[[B" down-line-or-search
    bindkey '^[[H' beginning-of-line
    bindkey '^[[F' end-of-line
    bindkey '^[[3~' delete-char
    bindkey '^[[1;5C' forward-word
    bindkey '^[[1;5D' backward-word

    # GPG configuration
    export GPG_TTY=$(tty)
    if [ -f "${config.home.homeDirectory}/.gpg-agent-info" ]; then
      . "${config.home.homeDirectory}/.gpg-agent-info"
      export GPG_AGENT_INFO
    fi

    # Set colored output
    export CLICOLOR=1
    export LSCOLORS=ExFxBxDxCxegedabagacad
  '';
}
