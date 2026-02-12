{ pkgs, ... }:
{
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

  initContent = ''
    # Shared portable config (aliases, options, keybindings, history)
    source ${builtins.toPath ../../../config/zsh/zshrc}

    # Nix-specific: powerlevel10k theme
    source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
    [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

    # Nix-specific: fzf integration
    if [ -n "$(command -v fzf)" ]; then
      source ${pkgs.fzf}/share/fzf/key-bindings.zsh
      source ${pkgs.fzf}/share/fzf/completion.zsh
    fi
  '';
}
