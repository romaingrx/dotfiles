# Prints the Tailscale logo to show (on or off) and a one-line tooltip, the
# output format of waybar's image module. The logos are rendered from lib/theme
# in modules/home/programs/waybar.nix and passed in as TAILSCALE_ON/OFF.
# shellcheck shell=bash

status=$(tailscale status --json 2>/dev/null) || status='{}'
if [[ $(jq -r '.BackendState // ""' <<<"$status") != Running ]]; then
  echo "$TAILSCALE_OFF"
  echo "Tailscale is off"
  exit 0
fi

echo "$TAILSCALE_ON"
jq -r '
  [.Peer[]?] as $peers
  | ([$peers[] | select(.ExitNode)][0].HostName) as $exit
  | "Tailscale  \(.Self.TailscaleIPs[0])  ·  \([$peers[] | select(.Online)] | length)/\($peers | length) peers online"
    + (if $exit then "  ·  exit node \($exit)" else "" end)
' <<<"$status"
