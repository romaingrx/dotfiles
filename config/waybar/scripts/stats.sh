# Streams one waybar JSON line per tick for `stats cpu|mem|net`: an icon, a
# btop-style braille graph of the last half minute and the current value. The
# tooltip holds a taller graph of the last two minutes with its average and
# peak. Colors come from the environment (set from lib/theme in
# modules/home/programs/waybar.nix).
# shellcheck shell=bash

kind=${1:?usage: stats cpu|mem|net}
interval=2
keep=60 # samples kept, for the tooltip graph: two minutes
shown=16 # samples on the bar: two per braille character

# Braille cell with `left` and `right` dots lit from the bottom, at
# cells[left * 5 + right].
cells=(⠀ ⢀ ⢠ ⢰ ⢸ ⡀ ⣀ ⣠ ⣰ ⣸ ⡄ ⣄ ⣤ ⣴ ⣼ ⡆ ⣆ ⣦ ⣶ ⣾ ⡇ ⣇ ⣧ ⣷ ⣿)

# graph ARRAY ROWS COUNT: the last COUNT values (0-100) of ARRAY as ROWS lines
# of braille, oldest first. Missing samples are left blank.
graph() {
  local -n values=$1
  local rows=$2 count=$3 out="" row i j level=() pad
  pad=$((count - ${#values[@]}))
  for ((i = 0; i < count; i++)); do
    j=$((i - pad))
    if ((j < 0)); then level+=(0); else level+=($(((values[j] * rows * 4 + 99) / 100))); fi
  done
  for ((row = rows - 1; row >= 0; row--)); do
    for ((i = 0; i < count; i += 2)); do
      out+=${cells[$(dots "${level[i]}" "$row") * 5 + $(dots "${level[i + 1]:-0}" "$row")]}
    done
    ((row)) && out+='\n'
  done
  printf '%s' "$out"
}

# Dots lit in braille row ROW (0 is the bottom) for a column of height LEVEL.
dots() {
  local d=$(($1 - $2 * 4))
  ((d < 0)) && d=0
  ((d > 4)) && d=4
  echo "$d"
}

push() { # ARRAY VALUE
  local -n into=$1
  into+=("$2")
  ((${#into[@]} > keep)) && into=("${into[@]:1}")
  return 0
}

stats() { # ARRAY: "avg peak" of the values
  local -n values=$1
  local v sum=0 peak=0
  for v in "${values[@]}"; do
    sum=$((sum + v))
    ((v > peak)) && peak=$v
  done
  echo "$((sum / ${#values[@]})) $peak"
}

state() {
  if (($1 >= 90)); then echo critical; elif (($1 >= 70)); then echo warning; else echo normal; fi
}

color() {
  case $1 in
    critical) echo "$THEME_DANGER" ;; warning) echo "$THEME_WARNING" ;; *) echo "$THEME_ACCENT" ;;
  esac
}

paint() { printf '<span color=\\"#%s\\">%s</span>' "$1" "$2"; }

emit() { # TEXT CLASS TOOLTIP
  printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$1" "$2" "$3"
}

# Bytes per second, four characters wide.
human() {
  awk -v b="$1" 'BEGIN {
    split("B K M G", u); i = 1
    while (b >= 1000 && i < 4) { b /= 1024; i++ }
    printf (b < 10 && i > 1) ? "%3.1f%s" : "%3d%s", b, u[i]
  }'
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
      percent '󰻠' CPU "$pct" "$cores cores · load $l1 $l5 $l15 · last 2 min"
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
    percent '󰍛' Memory "$pct" "$(awk -v u="$used" -v t="$total" -v s=$((swap_total - swap_free)) 'BEGIN {
      printf "%.1f / %.1f GiB · swap %.1f GiB · last 2 min", u / 1048576, t / 1048576, s / 1048576
    }')"
    sleep "$interval"
  done
}

# scale RATES OUT: RATES as 0-100 of their busiest sample, with a floor so an
# idle link stays flat.
scale() {
  local -n from=$1 to=$2
  local r peak=131072
  for r in "${from[@]}"; do ((r > peak)) && peak=$r; done
  to=()
  for r in "${from[@]}"; do to+=($((100 * r / peak))); done
}

net() {
  local iface rx tx prev_rx=0 prev_tx=0 down up addr dpeak upeak
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
      down=$(((rx - prev_rx) / interval)) up=$(((tx - prev_tx) / interval))
      push downs "$down"
      push ups "$up"
      scale downs down_graph
      scale ups up_graph
      read -r _ dpeak < <(stats downs)
      read -r _ upeak < <(stats ups)
      addr=$(ip -4 -brief address show dev "$iface" | awk '{ print $3 }')
      emit "$(paint "$THEME_MUTED" '󰈀') $(paint "$THEME_ACCENT" "$(graph down_graph 1 $shown)") $(human "$down")" normal \
        "<b>⇣</b> $(human "$down")/s  peak $(human "$dpeak")/s\\n$(paint "$THEME_ACCENT" "$(graph down_graph 2 $keep)")\\n<b>⇡</b> $(human "$up")/s  peak $(human "$upeak")/s\\n$(paint "$THEME_SECONDARY" "$(graph up_graph 2 $keep)")\\n$(paint "$THEME_MUTED" "$iface  $addr · last 2 min")"
    fi
    prev_rx=$rx prev_tx=$tx
    sleep "$interval"
  done
}

history=()
"$kind"
