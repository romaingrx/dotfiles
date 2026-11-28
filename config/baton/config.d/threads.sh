few_threads() {
  [[ ${1:-} == thread ]] || return 0
  local busy
  busy=$(hc ls --json --label role=thread |
    jq '[.terminals[]
      | select(.address | contains("/") | not)
      | select(.status == "working" or (.status == null and .turn == 0))] | length') || busy=
  [[ $busy =~ ^[0-9]+$ ]] || {
    echo "cannot count the threads at work on this machine" >&2
    return 1
  }
  ((busy < 3)) || {
    echo "$busy threads work or start on this machine, and the limit is 3: start this one when a thread stops working" >&2
    return 1
  }
}
prestart+=(few_threads)
