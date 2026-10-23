# Braille graphs and the sample bookkeeping shared by the status bars:
# config/waybar/scripts/stats.sh and config/sketchybar/providers/stats.sh.
# Each bar's Nix module prepends this file to its script. The caller sets
# `keep` (samples kept) and the THEME_ACCENT, THEME_WARNING and THEME_DANGER
# colors in its own format.
# shellcheck shell=bash

# Braille cell with `left` and `right` dots lit from the bottom, at
# cells[left * 5 + right].
cells=(⠀ ⢀ ⢠ ⢰ ⢸ ⡀ ⣀ ⣠ ⣰ ⣸ ⡄ ⣄ ⣤ ⣴ ⣼ ⡆ ⣆ ⣦ ⣶ ⣾ ⡇ ⣇ ⣧ ⣷ ⣿)

# graph ARRAY ROWS COUNT: the last COUNT values (0-100) of ARRAY as ROWS lines
# of braille (one per line), oldest first. Missing samples are left blank.
graph() {
  local -n values=$1
  local rows=$2 count=$3 out="" row i j left right level=() pad
  pad=$((count - ${#values[@]}))
  for ((i = 0; i < count; i++)); do
    j=$((i - pad))
    if ((j < 0)); then level+=(0); else level+=($(((values[j] * rows * 4 + 99) / 100))); fi
  done
  for ((row = rows - 1; row >= 0; row--)); do
    for ((i = 0; i < count; i += 2)); do
      # Dots lit in this row (0 is the bottom) for each column, 0 to 4.
      ((left = level[i] - row * 4, left = left < 0 ? 0 : left > 4 ? 4 : left))
      ((right = level[i + 1] - row * 4, right = right < 0 ? 0 : right > 4 ? 4 : right))
      out+=${cells[left * 5 + right]}
    done
    ((row)) && out+=$'\n'
  done
  printf '%s' "$out"
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

# Bytes per second, four characters wide.
human() {
  awk -v b="$1" 'BEGIN {
    split("B K M G", u); i = 1
    while (b >= 1000 && i < 4) { b /= 1024; i++ }
    printf (b < 10 && i > 1) ? "%3.1f%s" : "%3d%s", b, u[i]
  }'
}

# track RATES GRAPH VALUE: keep VALUE (bytes/s) in RATES and redraw GRAPH as
# 0-100 of the busiest sample, with a floor so an idle link stays flat.
track() {
  local -n rates=$1 scaled=$2
  local r peak=131072
  push "$1" "$3"
  for r in "${rates[@]}"; do ((r > peak)) && peak=$r; done
  scaled=()
  for r in "${rates[@]}"; do scaled+=($((100 * r / peak))); done
}
