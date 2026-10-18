{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    autocd = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Rebuild the completion dump at most once a day.
    completionInit = ''
      autoload -Uz compinit
      if [[ -n $HOME/.zcompdump(#qN.mh+24) ]]; then compinit; else compinit -C; fi
    '';

    history = {
      size = 50000;
      save = 50000;
      share = false;
      extended = true;
      ignoreDups = true;
      ignoreSpace = true;
      findNoDups = true;
      saveNoDups = true;
      expireDuplicatesFirst = true;
    };

    shellAliases = {
      ll = "ls -l";
      la = "ls -la";
      gs = "git status";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";
    };

    plugins = [
      {
        name = "zsh-vi-mode";
        src = pkgs.zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      }
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];

    initContent = ''
      setopt HIST_VERIFY INC_APPEND_HISTORY_TIME AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_MINUS

      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

      bindkey '^[[A' up-line-or-search
      bindkey '^[[B' down-line-or-search
      bindkey '^[[H' beginning-of-line
      bindkey '^[[F' end-of-line
      bindkey '^[[3~' delete-char
      bindkey '^[[1;5C' forward-word
      bindkey '^[[1;5D' backward-word

      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
    '';
  };

  programs.fzf = {
    enable = true;
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
    ];
    historyWidgetOptions = [
      "--sort"
      "--exact"
    ];
  };

  home.sessionVariables = {
    CLICOLOR = "1";
    LSCOLORS = "ExFxBxDxCxegedabagacad";
  };
}
