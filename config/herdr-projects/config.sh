min_free_gib=8

gateway=$HOME/.claude/gateway-settings.json
if [[ -f $gateway ]]; then
  prestart() {
    sh -c "$(jq -r .apiKeyHelper "$gateway")" >/dev/null 2>&1 || {
      echo "the Claude gateway token helper fails: sign in first" >&2
      return 1
    }
  }

  run_claude() { exec claude --settings "$gateway" "$@"; }
fi
