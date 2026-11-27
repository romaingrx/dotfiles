few_threads() {
  [[ ${1:-} == thread ]] || return 0
  local working
  working=$(hc ls --json --label role=thread |
    jq '[.terminals[] | select((.address | contains("/") | not) and .status == "working")] | length')
  ((working < 3)) || {
    echo "three threads work already on this machine: the task waits until one ends" >&2
    return 1
  }
}
prestart+=(few_threads)
