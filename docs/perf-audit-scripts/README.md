# Measurement scripts, August 2026 performance audit

Preserved as run, so the numbers in [`../perf-audit-2026-08.md`](../perf-audit-2026-08.md)
can be re-derived rather than taken on trust. They are throwaway instruments, not
maintained tooling — paths and the 16-core divisor are hardcoded for `goddard`.

Two of them are here **because they failed**. An instrument that failed its own
validation is worth keeping: it stops the next pass from spending a day
rediscovering the same dead end.

## Working instruments

| Script | What it measures |
| --- | --- |
| `forkcount.py` | Process creations, via libproc `proc_listallpids()` sampled in-process at ~1.6 ms. The instrument never forks. `validate` mode injects 300 known forks and reports the capture rate (97%). |
| `ab_forkrate.py` | A/B of the two sketchybar configs by direct fork count. The headline confirmation: −3159 forks/min, paired t = −65.8. |
| `forktax.py` | Per-process CPU attributable to forked children, via `os.times()` child accounting. |
| `cpudelta.py` | Cumulative CPU-time deltas from `ps -o time=`. Use this, never `ps -o %cpu`, which is a lifetime average. |
| `microbench.py` | Per-invocation cost of individual shell commands, used to build the cost table in §1.2. |
| `paired.py` | Paired-difference analysis with a t-statistic, for any alternating A/B. |
| `ab_sketchybar.sh` | Config A/B by `launchctl bootout`/`bootstrap` — never `kill`, which KeepAlive defeats. |
| `forkrate.py`, `hostcpu.py`, `topconfirm.py` | Supporting counters and cross-checks. |

## Rejected instruments

| Script | Why it was rejected |
| --- | --- |
| `ab_top.sh` | Whole-system `top` A/B. Did not resolve: pairs −13.28, −10.40, **+9.44**; t = −0.66. Background drift (~30% of one core) is twice the effect size. A null here is an instrument limit, not counter-evidence. |
| `ab_airdrop.sh` | The harness was broken, not the hypothesis. `launchctl kickstart` on `com.apple.sharingd` fails under SIP with `150: Operation not permitted`, and the script sent that stderr to `/dev/null`. sharingd never reloaded the preference, so nothing was ever tested. AirDrop remains an open question. |
| `ab_postfix.sh` | Superseded; kept for the postfix figures only. |

Not scripted, and rejected during the audit: PID-allocation-delta fork counting
(Darwin reuses freed PIDs — saw 163 of 500 injected), and a raw `host_statistics`
ctypes counter (attributed 0.46 of an expected 8.00 core-seconds).

## Traps these scripts encode

1. **Second `top` sample only.** The first is a lifetime average.
2. **Never `2>/dev/null` a setup command.** That is how the AirDrop A/B silently
   measured nothing for an hour.
3. **Verify the effect, not the setting.** `defaults read` returning your new
   value only confirms your own write landed.
4. **Use `/usr/bin/log`, not `log`.** A zsh function shadows it and returns zero
   lines, which reads exactly like "this process produces no logs."
5. **Read `sketchybarrc`'s source list before costing an item.** `darkside.sh`
   was projected at 1.6% of a core before it turned out never to be sourced.
