enough_memory() {
  command -v free >/dev/null || return 0
  local free_gib
  free_gib=$(LC_ALL=C free -g | awk '/^Mem:/{print $7}')
  if [[ $free_gib =~ ^[0-9]+$ ]] && ((free_gib < 8)); then
    echo "only $free_gib GiB of memory is free: close idle sessions first" >&2
    return 1
  fi
}
prestart+=(enough_memory)
