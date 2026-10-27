# Feeds the stats.cpu, stats.mem and stats.net items (items/stats.sh) every
# two seconds: a bar graph of the last 16 seconds and the current value on
# the bar, and the last two minutes with average and peak in
# the hover popup, like the waybar modules. The graph helpers come from
# config/statusbar/graph.sh. Built with Nix's bash by
# modules/darwin/services/sketchybar, since the bash macOS ships has no
# namerefs. Colors come from colors.sh (lib/theme).
# shellcheck shell=bash

# shellcheck source=/dev/null
source "${CONFIG_DIR:-$HOME/.config/sketchybar}/colors.sh"

# One feeder at a time: the newest replaces any earlier one, which then
# notices on its next tick and exits.
pidfile=${TMPDIR:-/tmp}/sketchybar-stats.pid
echo $$ >"$pidfile"

args=() # the `sketchybar` call for this tick, sent once at its end

label() { # ITEM COLOR TEXT
  args+=(--set "$1" label.color="$2" label="$3")
}

# lines ITEM FIRST COLOR GRAPH: each line of GRAPH on popup rows ITEM.FIRST on.
lines() {
  local row=$2 line
  while IFS= read -r line; do
    label "$1.$row" "$3" "$line"
    row=$((row + 1))
  done <<<"$4"
}

# percent ITEM NAME HISTORY VALUE DETAILS: the bar and popup (rows 0-4) for a
# 0-100 metric.
percent() {
  local hue
  hue=$(color "$(state "$4")")
  label "$1" "$hue" "$(spark "$3") $(printf '%3d%%' "$4")"
  label "$1.0" "$THEME_FG" "$(summary "$2" "$4" "$3")"
  lines "$1" 1 "$hue" "$(history_graph "$3" 3)"
  label "$1.4" "$THEME_MUTED" "$5 · $window"
}

# direction ITEM FIRST ARROW RATES GRAPH COLOR: a popup block (3 rows) for
# one direction of the network.
direction() {
  local -n rates=$4
  local peak
  read -r _ peak < <(stats "$4")
  label "$1.$2" "$THEME_FG" "$3 $(human "${rates[-1]}")/s  peak $(human "$peak")/s"
  lines "$1" $(($2 + 1)) "$6" "$(history_graph "$5" 2)"
}

cores=$(sysctl -n hw.logicalcpu)
memory=$(sysctl -n hw.memsize)
cpus=()

# Also the clock: the second report covers the last `interval` seconds.
cpu() {
  local user system l1 l5 l15 pct
  read -r user system _ l1 l5 l15 < <(iostat -C -U -n 0 -c 2 -w "$interval" | tail -n 1)
  pct=$((user + system))
  push cpus "$pct"
  percent stats.cpu CPU cpus "$pct" "$cores cores · load $l1 $l5 $l15"
}

mems=()

# Used is what Activity Monitor counts: active, wired and compressed pages.
mem() {
  local used swap pct
  used=$(vm_stat | awk '
    /page size of/ { page = $8 }
    /^Pages (active|wired down|occupied by compressor):/ { pages += $NF }
    END { print pages * page }')
  swap=$(sysctl -n vm.swapusage | awk '{ print $6 }')
  pct=$((100 * used / memory))
  push mems "$pct"
  percent stats.mem Memory mems "$pct" "$(awk -v u="$used" -v t="$memory" -v s="$swap" 'BEGIN {
    printf "%.1f / %.1f GiB · swap %s", u / 2^30, t / 2^30, s
  }')"
}

downs=() ups=() down_graph=() up_graph=() prev_rx=0 prev_tx=0

net() {
  local iface rx tx addr
  # The interface holding the default route, so nothing is hard-coded.
  iface=$(route -n get default 2>/dev/null | awk '/interface:/ { print $2 }')
  if [[ -z $iface ]]; then
    downs=() ups=() prev_rx=0
    label stats.net "$THEME_DANGER" offline
    return
  fi
  # Byte counters from the link row; tunnels have no address column.
  read -r rx tx < <(netstat -ibn -I "$iface" | awk '$3 ~ /^<Link/ {
    o = $4 ~ /:/ ? 0 : -1; print $(7 + o), $(10 + o); exit }')
  if ((prev_rx)); then
    track downs down_graph $(((rx - prev_rx) / interval))
    track ups up_graph $(((tx - prev_tx) / interval))
    addr=$(ipconfig getifaddr "$iface" 2>/dev/null || true)
    label stats.net "$THEME_ACCENT" "$(spark down_graph) $(human "${downs[-1]}")"
    direction stats.net 0 ⇣ downs down_graph "$THEME_ACCENT"
    direction stats.net 3 ⇡ ups up_graph "$THEME_SECONDARY"
    label stats.net.6 "$THEME_MUTED" "$iface  ${addr:-no IPv4} · $window"
  fi
  prev_rx=$rx prev_tx=$tx
}

while [[ $(<"$pidfile") == "$$" ]]; do
  cpu
  mem
  net
  sketchybar "${args[@]}"
  args=()
done
