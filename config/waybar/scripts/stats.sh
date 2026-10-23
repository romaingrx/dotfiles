# Streams one waybar JSON line per tick for `stats cpu|mem|net`: an icon, a
# btop-style braille graph of the last half minute and the current value. The
# tooltip holds a taller graph of the last two minutes with its average and
# peak. The graph helpers come from config/statusbar/graph.sh. Colors come
# from the environment (set from lib/theme in modules/home/programs/waybar.nix).
# shellcheck shell=bash

kind=${1:?usage: stats cpu|mem|net}
interval=2
keep=60 # samples kept, for the tooltip graph: two minutes
shown=16 # samples on the bar: two per braille character

paint() { printf '<span color=\\"#%s\\">%s</span>' "$1" "$2"; }

emit() { # TEXT CLASS TOOLTIP, with newlines escaped for JSON
  printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$1" "$2" "${3//$'\n'/\\n}"
}

# percent ICON NAME VALUE DETAILS: the bar and tooltip for a 0-100 metric kept
# in `history`.
percent() {
  local avg peak cls
  read -r avg peak < <(stats history)
  cls=$(state "$3")
  emit "$(paint "$THEME_MUTED" "$1") $(paint "$(color "$cls")" "$(graph history 1 $shown)") $(printf '%3d%%' "$3")" "$cls" \
    "<b>$2</b>  $3%    avg $avg%  peak $peak%\\n$(paint "$(color "$cls")" "$(graph history 3 $keep)")\\n$(paint "$THEME_MUTED" "$4")"
}

cpu() {
  local prev_total=0 prev_idle=0 total idle pct cores l1 l5 l15
  cores=$(nproc)
  while :; do
    read -r _ user nice system idle iowait irq softirq steal _ </proc/stat
    total=$((user + nice + system + idle + iowait + irq + softirq + steal))
    idle=$((idle + iowait))
    if ((prev_total)); then
      pct=$((100 * (total - prev_total - idle + prev_idle) / (total - prev_total)))
      push history "$pct"
      read -r l1 l5 l15 _ </proc/loadavg
      percent '' CPU "$pct" "$cores cores · load $l1 $l5 $l15 · last 2 min"
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
    push history "$pct"
    percent '' Memory "$pct" "$(awk -v u="$used" -v t="$total" -v s=$((swap_total - swap_free)) 'BEGIN {
      printf "%.1f / %.1f GiB · swap %.1f GiB · last 2 min", u / 1048576, t / 1048576, s / 1048576
    }')"
    sleep "$interval"
  done
}

# direction ARROW RATES GRAPH COLOR: a tooltip block for one direction.
direction() {
  local -n rates=$2
  local peak
  read -r _ peak < <(stats "$2")
  printf '<b>%s</b> %s/s  peak %s/s\\n%s' "$1" "$(human "${rates[-1]}")" "$(human "$peak")" \
    "$(paint "$4" "$(graph "$3" 2 $keep)")"
}

net() {
  local iface rx tx prev_rx=0 prev_tx=0 addr
  local downs=() ups=() down_graph=() up_graph=()
  while :; do
    # The interface holding the default route, so nothing is hard-coded.
    iface=$(awk '$2 == "00000000" { print $1; exit }' /proc/net/route)
    if [[ -z $iface ]]; then
      downs=() ups=() prev_rx=0
      emit "$(paint "$THEME_DANGER" '󰈂')" disconnected Disconnected
      sleep "$interval"
      continue
    fi
    read -r rx </sys/class/net/"$iface"/statistics/rx_bytes
    read -r tx </sys/class/net/"$iface"/statistics/tx_bytes
    if ((prev_rx)); then
      track downs down_graph $(((rx - prev_rx) / interval))
      track ups up_graph $(((tx - prev_tx) / interval))
      addr=$(ip -4 -brief address show dev "$iface" | awk '{ print $3 }')
      emit "$(paint "$THEME_MUTED" '󰈀') $(paint "$THEME_ACCENT" "$(graph down_graph 1 $shown)") $(human "${downs[-1]}")" normal \
        "$(direction ⇣ downs down_graph "$THEME_ACCENT")\\n$(direction ⇡ ups up_graph "$THEME_SECONDARY")\\n$(paint "$THEME_MUTED" "$iface  $addr · last 2 min")"
    fi
    prev_rx=$rx prev_tx=$tx
    sleep "$interval"
  done
}

history=()
"$kind"
