# Terminal `claude` loads ~/.claude/gateway-settings.json when the machine has one, so a
# work gateway's settings stay out of this repo and the desktop app keeps its own login.
_: {
  programs.zsh.initContent = ''
    claude() {
      if [[ -f $HOME/.claude/gateway-settings.json ]]; then
        command claude --settings "$HOME/.claude/gateway-settings.json" "$@"
      else
        command claude "$@"
      fi
    }
  '';
}
