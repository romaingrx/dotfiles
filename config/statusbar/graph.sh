# Bar graphs and the sample bookkeeping shared by the status bars:
# config/waybar/scripts/stats.sh and config/sketchybar/providers/stats.sh.
# Each bar's Nix module prepends this file to its script. The caller sets
# `keep` (samples kept) and the THEME_ACCENT, THEME_WARNING and THEME_DANGER
# colors in its own format.
# shellcheck shell=bash

# Block heights, from blank to full.
bars=(' ' ▁ ▂ ▃ ▄ ▅ ▆ ▇ █)

# graph ARRAY ROWS SAMPLES COLS: the last SAMPLES values (0-100) of ARRAY as
# ROWS lines (one per line) of COLS block bars, oldest first. Each bar is the
# peak of its share of the samples, at least a sliver so an idle graph still
# shows. Bars with no samples yet are left blank.
graph() {
  local -n values=$1
  local rows=$2 samples=$3 cols=$4 out="" row c k j v peak span level=() pad
  span=$((samples / cols))
  pad=$((samples - ${#values[@]}))
  for ((c = 0; c < cols; c++)); do
    peak=-1
    for ((k = 0; k < span; k++)); do
      j=$((c * span + k - pad))
      ((j >= 0 && values[j] > peak)) && peak=${values[j]}
    done
    if ((peak < 0)); then
      level+=(-1)
    else
      ((v = (peak * rows * 8 + 99) / 100, v = v < 1 ? 1 : v))
      level+=("$v")
    fi
  done
  for ((row = rows - 1; row >= 0; row--)); do
    for ((c = 0; c < cols; c++)); do
      # Eighths of this row (0 is the bottom) filled for this bar, 0 to 8.
      ((v = level[c] - row * 8, v = v < 0 ? 0 : v > 8 ? 8 : v))
      out+=${bars[v]}
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
