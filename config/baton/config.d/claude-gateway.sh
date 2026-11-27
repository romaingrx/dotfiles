gateway=$HOME/.claude/gateway-settings.json
if [[ -f $gateway ]]; then
  gateway_token() {
    local helper
    helper=$(jq -er .apiKeyHelper "$gateway") && sh -c "$helper" >/dev/null 2>&1 || {
      echo "the Claude gateway token helper fails: sign in first" >&2
      return 1
    }
  }
  prestart+=(gateway_token)
  claude_args+=(--settings "$gateway")
fi
