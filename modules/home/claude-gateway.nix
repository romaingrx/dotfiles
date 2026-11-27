# Claude goes through the work gateway on a machine that has
# ~/.claude/gateway-settings.json: in a terminal, and in a session that Baton
# starts. The gateway's settings stay out of this repo, and the desktop app
# keeps its own login.
_:
let
  settings = "$HOME/.claude/gateway-settings.json";
in
{
  programs.zsh.initContent = ''
    claude() {
      if [[ -f ${settings} ]]; then
        command claude --settings "${settings}" "$@"
      else
        command claude "$@"
      fi
    }
  '';

  xdg.configFile."baton/config.d/claude-gateway.sh".text = ''
    gateway=${settings}
    if [[ -f $gateway ]]; then
      gateway_token() {
        sh -c "$(jq -r .apiKeyHelper "$gateway")" >/dev/null 2>&1 || {
          echo "the Claude gateway token helper fails: sign in first" >&2
          return 1
        }
      }
      prestart+=(gateway_token)
      claude_args+=(--settings "$gateway")
    fi
  '';
}
