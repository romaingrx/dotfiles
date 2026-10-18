# Streams one waybar JSON line per tick for `stats cpu|mem|net`: an icon, a
# sparkline of the last samples and the current value. Colors come from the
# environment (set from lib/theme in modules/home/programs/waybar.nix).
# shellcheck shell=bash

kind=${1:?usage: stats cpu|mem|net}
interval=2
width=8
bars=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)
history=()

# Sparkline of `history` (0-100), oldest first, padded so the width is fixed.
graph() {
  local out="" v
  for ((i = ${#history[@]}; i < width; i++)); do out+=" "; done
  for v in "${history[@]}"; do out+=${bars[v * 7 / 100]}; done
  printf '%s' "$out"
}

push() {
  history+=("$1")
  ((${#history[@]} > width)) && history=("${history[@]:1}")
  return 0
}

state() {
  if (($1 >= 90)); then echo critical; elif (($1 >= 70)); then echo warning; else echo normal; fi
}

color() {
  case $1 in
    critical) echo "$THEME_DANGER" ;; warning) echo "$THEME_WARNING" ;; *) echo "$THEME_ACCENT" ;;
  esac
}

emit() { # icon value class tooltip
  printf '{"text":"<span color=\\"#%s\\">%s</span> <span color=\\"#%s\\">%s</span> %s","class":"%s","tooltip":"%s"}\n' \
    "$THEME_MUTED" "$1" "$(color "$3")" "$(graph)" "$2" "$3" "$4"
}

# Bytes per second, four characters wide.
human() {
  awk -v b="$1" 'BEGIN {
    split("B K M G", u); i = 1
    while (b >= 1000 && i < 4) { b /= 1024; i++ }
    printf (b < 10 && i > 1) ? "%3.1f%s" : "%3d%s", b, u[i]
  }'
}

cpu() {
  local prev_total=0 prev_idle=0 total idle pct cores
  cores=$(nproc)
  while :; do
    read -r _ user nice system idle iowait irq softirq steal _ </proc/stat
    total=$((user + nice + system + idle + iowait + irq + softirq + steal))
    idle=$((idle + iowait))
    if ((prev_total)); then
      pct=$((100 * (total - prev_total - idle + prev_idle) / (total - prev_total)))
      push "$pct"
      read -r l1 l5 l15 _ </proc/loadavg
      emit '󰻠' "$(printf '%3d%%' "$pct")" "$(state "$pct")" \
        "CPU $pct% across $cores cores\\nLoad $l1  $l5  $l15"
    fi
    prev_total=$total prev_idle=$idle
    sleep "$interval"
  done
}

mem() {
  local key value total avail swap_total swap_free used pct
  while :; do
    while read -r key value _; do
      case $key in
        MemTotal:) total=$value ;; MemAvailable:) avail=$value ;;
        SwapTotal:) swap_total=$value ;; SwapFree:) swap_free=$value ;;
      esac
    done </proc/meminfo
    used=$((total - avail))
    pct=$((100 * used / total))
    push "$pct"
    emit '󰍛' "$(printf '%3d%%' "$pct")" "$(state "$pct")" \
      "$(awk -v u="$used" -v t="$total" -v s=$((swap_total - swap_free)) 'BEGIN {
        printf "Memory %.1f / %.1f GiB\\nSwap %.1f GiB", u / 1048576, t / 1048576, s / 1048576
      }')"
    sleep "$interval"
  done
}

net() {
  local iface rx tx prev_rx=0 prev_tx=0 down up peak floor=131072 addr
  while :; do
    # The interface holding the default route, so nothing is hard-coded.
    iface=$(awk '$2 == "00000000" { print $1; exit }' /proc/net/route)
    if [[ -z $iface ]]; then
      history=() prev_rx=0
      printf '{"text":"<span color=\\"#%s\\">%s</span>","class":"disconnected","tooltip":"Disconnected"}\n' \
        "$THEME_DANGER" '󰈂'
      sleep "$interval"
      continue
    fi
    read -r rx </sys/class/net/"$iface"/statistics/rx_bytes
    read -r tx </sys/class/net/"$iface"/statistics/tx_bytes
    if ((prev_rx)); then
      down=$(((rx - prev_rx) / interval)) up=$(((tx - prev_tx) / interval))
      rates+=("$down")
      ((${#rates[@]} > width)) && rates=("${rates[@]:1}")
      # Scale the graph to the busiest sample, with a floor so idle stays flat.
      peak=$floor
      for r in "${rates[@]}"; do ((r > peak)) && peak=$r; done
      history=()
      for r in "${rates[@]}"; do history+=($((100 * r / peak))); done
      addr=$(ip -4 -brief address show dev "$iface" | awk '{ print $3 }')
      emit '󰈀' "$(human "$down")" normal \
        "$iface  $addr\\n⇣ $(human "$down")/s  ⇡ $(human "$up")/s"
    fi
    prev_rx=$rx prev_tx=$tx
    sleep "$interval"
  done
}

rates=()
"$kind"
