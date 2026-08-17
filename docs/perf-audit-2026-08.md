# Idle CPU / power audit — `goddard`, 2026-08-08

Continues the investigation described in `PERF-AUDIT-BRIEF.md`. Everything below was
measured on this machine on 2026-08-08/09 unless explicitly labelled **INFERENCE**.
Measurement scripts are in the session scratchpad: `cpudelta.py` (CPU-time delta sampler),
`forktax.py` (replay + `os.times()` child accounting), `microbench.py` (per-command cost),
and the three `ab_*.sh` A/B harnesses.

**All percentages are % of ONE core.** The machine has 16 (12P + 4E), so 100% here is
6.25% of total capacity. Whole-system idle load measured 69–81% of one core across nine
90-second windows, i.e. the box sits ~95% idle. Nothing in this document was capable of
making this machine hot; the goal is removing pointless work and stopping things that
block idle sleep.

---

## 0. Summary — ranked by measured CPU saved

| # | Change | Measured saving (% of one core) | Status |
|---|---|---|---|
| 1 | sketchybar polling rewrite (5 items) | **~15** (11.9 forks, corroborated 3 ways + ~3 induced daemons) | Applied in this worktree; **86% of all system forks eliminated**, see §1.6 |
| 2 | Contacts/CardDAV failed-sync loop | **~10** + unblocks idle sleep | **Needs a decision from you** — an account credential problem, not config |
| 3 | `storagekitd` Preboot retry loop | **~3–5** | **Needs sudo** — evidence is now solid, prior pass's reasoning was not |
| 4 | `airportd` | ~4.9 sustained | Root cause identified; the one candidate lever (AirDrop) is **untested — see §4.2**, my harness silently failed |
| 5 | `pmset` battery `displaysleep` | not CPU — battery only, but probably the largest item here | Ready, needs your OK |
| 6 | Duplicate/dead network services | not measurable at idle | Ready, needs your OK |

Only item 1 is applied, and only in this worktree — `~/.dotfiles` was never modified and
the running machine is byte-for-byte as it was before this audit.

**If you only read one section, read §6 (Action list).**

The three biggest consumers on this machine at idle — Contacts (~10), `airportd` (~4.9)
and `storagekitd` (~3–5) — are all **system daemons in failure loops**, not configuration.
Together they are roughly 18% of one core burning continuously for no result. That is more
than the entire status bar was costing.

---

## 1. What was actually costing CPU

### 1.1 The sketchybar fork tax, re-measured and attributed per script

Method: replay each plugin N=150 times and read `os.times()` child accounting
(`children_user + children_system`). This is the only way to see the cost — every one of
these scripts spends most of its time in short-lived `ps`/`awk`/`networksetup` children
that Activity Monitor never attributes to anything.

| plugin | freq (/min) | before (ms/invoke) | after (ms/invoke) | before (%core) | after (%core) |
|---|---|---|---|---|---|
| `mode.sh` | 60 → 0 (event) | 21.5 | — | 2.15 | **0.00** |
| `clock.sh` | 60 → 4 | 8.9 | 9.0 | 0.89 | **0.06** |
| `cpu.sh` | 30 → 6 | 91.0 | 41.3 | 4.55 | **0.41** |
| `wifi.sh` → `net_activity.sh` | 30 → 6 | 95.3 | 21.7 | 4.77 | **0.22** |
| `wifi.sh` (wifi.control) | 2 | 95.3 | 47.7 | 0.32 | **0.16** |
| `battery.sh` | 2 | 53.8 | ~40 | 0.18 | **0.13** |
| **total own-subtree** | | | | **12.85** | **0.98** |

**Own-subtree saving: 11.9% of one core, a 92% reduction.**

`cpu.sh` and `net.activity` alone were 9.3 of the 12.85 — 72% of the whole status bar's
cost sat in two widgets on 2-second timers.

### 1.2 Cost of the individual commands these scripts call

Measured the same way, n=40. This table is the reusable part of this audit — it is what
lets you cost a status-bar widget before writing it.

| command | ms of CPU per call |
|---|---|
| `system_profiler SPAirPortDataType` | **302.5** |
| `scutil --nc list` | **24.0** |
| `ps -Axo pcpu,user,ucomm` | 22.0 |
| `ps -eo pcpu,user` | 21.8 |
| `networksetup -listallhardwareports` | **19.2** |
| `ps axo %cpu,ucomm` | 17.5 |
| `networksetup -getairportnetwork en0` | 9.6 |
| `pmset -g batt` | 6.3 |
| `aerospace list-modes --current` | 6.2 |
| `defaults read -g AppleInterfaceStyle` | 4.5 |
| `sketchybar --set …` | 4.5 |
| `ipconfig getsummary en0` | 4.4 |
| `wdutil info` | 4.0 |
| `ipconfig getifaddr en0` | 3.0 |
| `netstat -ibn` | 2.3 |
| `whoami` | 2.2 |
| `ifconfig en0` | 2.0 |
| `sysctl -n …` | 1.8 |
| `uname -s` | 1.8 |
| `/bin/bash -c :` (bare fork+exec) | 1.8 |
| `date +%s` | 1.7 |

Sourcing `env.sh` + `colors.sh` + helpers costs ~10 ms, which is the practical floor for
any bash sketchybar plugin. A plugin cannot be cheaper than ~15 ms including its
`sketchybar --set`.

### 1.3 A/B — sketchybar running vs genuinely stopped

`launchctl bootout gui/$UID/org.nixos.sketchybar`, verified gone with `pgrep`, restored
with `bootstrap` under a `trap`. Three 90-second windows.

| process | control (running) | treatment (stopped) | treatment-2 | Δ |
|---|---|---|---|---|
| **TOTAL, all processes** | 75.34 | 69.32 | 70.39 | **−5.48** |
| AeroSpace | 2.10 | absent | absent | **−2.10** |
| sketchybar itself | 1.17 | gone | gone | −1.17 |
| `opendirectoryd` | 3.16 | 2.02 | 2.31 | **−0.99** |
| `launchd` | 1.48 | 0.84 | 0.84 | −0.64 |
| `notifyd` | 1.05 | 0.58 | 0.60 | −0.47 |
| `cfprefsd` (×2) | 1.65 | below cutoff | below cutoff | ≈ −1.2 |
| `launchservicesd` | 0.63 | below cutoff | below cutoff | ≈ −0.6 |
| `logd` | 0.85 | 0.55 | 0.55 | −0.30 |

**Verification that sketchybar was really down for the whole window** (brief §4 trap #3 —
a `KeepAlive=true` agent respawns in under a second, and §4.2 of this document is a live
example of the same mistake in a different form):

| check | result |
|---|---|
| method | `launchctl bootout`, never `kill` |
| `pgrep` gate 3 s after bootout | empty; the script `exit 1`s and abandons the run otherwise |
| PID across the run | **38075 → 99609** — `restore()` only calls `bootstrap` inside `if ! pgrep`, so a new PID proves it was still absent ~185 s later, at the end of both windows |
| sketchybar in top-30 | 1.17% in control → **absent** in both treatment windows |
| AeroSpace, induced-load canary | 2.10% → **absent** in both treatment windows |

The last two are whole-window evidence rather than point checks, because they are
cumulative CPU deltas over the full 90 s. For AeroSpace to fall below the 0.45% reporting
cutoff, sketchybar can have polled for at most (0.45/2.10) x 90 ≈ 19 s of the 90 — and the
PID change puts it at zero.

**Confounders sampled in both windows** (brief §4 rule 4): `contactsd` rose 5.93 → 6.86,
Tailscale rose 1.95 → 2.87, `airportd` rose 4.63 → 5.11, this `claude` process fell
15.49 → 14.05. The confounders moved *against* the treatment, so −5.48 is conservative.

Two findings from this table:

- **The brief's AeroSpace result reproduces exactly.** AeroSpace goes to zero when
  sketchybar stops. It was never AeroSpace's cost.
- **`opendirectoryd` was also induced, which was not previously known.** `cpu.sh` called
  `whoami` twice per invocation *and* ran `ps -eo pcpu,user`, which resolves a username
  for every one of ~600 processes, 30 times a minute. That is what was driving
  `opendirectoryd`.

### 1.4 Why −5.48 and not −12.85

They measure different things and both are right. `ps`-delta sampling can only see
processes that exist at both snapshots; a `bash`/`awk`/`ps` child that is born and reaped
between them appears in **neither**, so its CPU is invisible. The −5.48 is the induced
cost in *surviving* daemons plus the sketchybar parent. The 12.85 is the fork cost itself,
which only `os.times()` child accounting can see.

Total sketchybar cost ≈ 12.85 (forks) + 2.10 (AeroSpace) + 1.17 (parent) + ~3.2 (other
daemons, from §1.3) ≈ **19.3% of one core**, corroborating the brief's 17–18% estimate by
an independent route.

**This is a trap for the next pass:** any "total system CPU" number built from `ps`
sampling systematically undercounts fork-heavy workloads. Do not use it to evaluate a
change that alters fork *count*.

### 1.5 A/B — current config vs the fixed config (the after-measurement)

Method: repoint `~/.config/sketchybar` at this worktree, `launchctl kickstart -k`, measure;
restore under a `trap`. `~/.dotfiles` untouched throughout. The fixed config was verified
to have actually loaded by checking that the `wifi.speed` item was gone, and the restore
verified by checking it was back.

| process | control (current) | fixed-1 | fixed-2 | Δ |
|---|---|---|---|---|
| **AeroSpace** | 2.85 | below cutoff | 0.79 | **−2.46** |
| `launchservicesd` | 0.92 | below cutoff | below cutoff | **−0.92** |
| `cfprefsd` | 0.49 | below cutoff | below cutoff | **−0.49** |
| `notifyd` | 0.77 | 0.61 | 0.59 | −0.17 |
| `logd` | 0.74 | 0.57 | 0.57 | −0.17 |
| `opendirectoryd` | 2.57 | 2.49 | 2.39 | −0.13 |
| `launchd` | 0.97 | 0.88 | 0.81 | −0.12 |
| **sum of induced savings** | | | | **−4.46** |
| **TOTAL, all processes** | 68.80 | 67.05 | 71.18 | **+0.32** |

**Read that last row carefully — it is the point of brief §4 rule 4.** The total went
*up*, and the change still worked. Confounders moved +3.88 against the treatment in the
same windows: this `claude` process +0.99, `AddressBookSourceSync` +1.18, `airportd`
+0.74, Tailscale +0.40, `contactsd` +0.25, `configd` +0.14, `WiFiAgent` +0.12,
`storagekitd` +0.06. Anyone quoting the total here would have concluded the fix did
nothing.

The per-process rows are unambiguous, and **AeroSpace is the clean confirmation**:
2.85 → ~0.40 with nothing changed except sketchybar no longer polling it. That
independently reproduces §1.3, where AeroSpace went to zero when sketchybar was stopped
outright. AeroSpace's entire idle cost really was the mode poll.

**Total measured saving: 11.9 (forks, §1.1) + 4.46 (induced daemons, above) ≈ 16.3% of one
core**, or ~1.0% of the 16-core box. Cross-check: §1.3 put the whole status bar at ~19.3%;
removing 16.3 leaves ~3%, which is the sketchybar parent process plus the 0.98% of forks
that remain. Consistent.

---

### 1.6 Independent confirmation by direct fork counting

The 12.85% figure rests on `os.times()` child accounting. That is one instrument, so it
was worth confirming with something that shares no code path with it. Three were tried;
two failed their own validation step and are recorded here so nobody repeats them.

**Rejected instrument 1 — PID-allocation delta.** Darwin assigns PIDs from an increasing
counter, so the PID delta over a window should equal processes created. Validation
injected 500 processes; the counter saw **163**. Darwin reuses recently-freed PIDs, so it
undercounts precisely the short-lived-process workload in question. Unusable.

**Rejected instrument 2 — whole-system CPU% A/B via `top`.** Real sketchybar, real polling
rates, alternating ORIGINAL/FIXED, 3 pairs of 45 s:

| pair | ORIGINAL | FIXED | delta |
|---|---|---|---|
| 1 | 228.64 | 215.36 | **−13.28** |
| 2 | 289.60 | 279.20 | **−10.40** |
| 3 | 251.20 | 260.64 | **+9.44** |

Mean −4.75, sd 12.37, paired t = −0.66. **Not resolved.** The absolute load drifted 61
points between windows against an effect of ~15, and pairing did not cancel enough of it.
This is not evidence against the saving — it is an instrument without the resolution for
it. Worth internalising: whole-system CPU% has a noise floor around ±30% of one core on
this machine, so it cannot settle any question smaller than that. Two pairs in, the mean
was −11.84 with sd 2.04 and it looked conclusive; the third pair flipped sign. **n=2 is
not a result.**

**Working instrument — direct fork count.** `libproc`'s `proc_listallpids()` sampled
in-process at ~1.6 ms, counting PIDs absent from the previous sample. The instrument never
forks, so it does not perturb what it measures. Validated by injecting 300 real forks:
**97% capture rate**.

| pair | ORIGINAL | FIXED | delta |
|---|---|---|---|
| 1 | 3596 forks/min | 498 | **−3098 (−86.2%)** |
| 2 | 3654 forks/min | 528 | **−3126 (−85.6%)** |
| 3 | 3806 forks/min | 552 | **−3254 (−85.5%)** |

**Mean −3159 forks/min, sd 83, paired t = −65.8, all three pairs the same sign.**

Two things follow.

**sketchybar was responsible for 86% of all process creation on this machine** — 3159 of
3685 forks per minute, system-wide, everything else included.

**And it reproduces the CPU figure from an unrelated direction.** Dividing the independently
measured CPU saving by the independently measured fork saving gives the average cost of one
fork:

```
11.87% of one core = 7.12 core-seconds/minute
7.12 s / 3159 forks = 2.25 ms per fork
```

§1.2 measured a bare `/bin/bash -c :` fork+exec at **1.8 ms**, with a minority of much
costlier calls (`ps` 22 ms, `scutil` 24 ms, `networksetup` 19 ms) mixed in. An average of
2.25 ms is exactly what that distribution predicts. The fork count and the CPU accounting
were measured by different mechanisms and multiply out to the same total.

**Revised confidence.** The fork half (11.87%) is now corroborated three ways: `os.times()`
child accounting, per-command microbenchmarks, and direct fork counting. The induced-daemon
half is weaker than §1.5 implied — AeroSpace's 2.46 was measured twice and is solid, but the
`launchservicesd` (−0.92) and `cfprefsd` (−0.49) rows were scored as full drops when they
had merely fallen below the reporting cutoff, so their true drop is smaller. A defensible
total is **~15% of one core** (≈0.9% of the box), of which ~12 is well established and ~3 is
approximate.

---

## 2. Changes applied in this worktree

`~/.dotfiles` was not touched. `config/sketchybar/` is live-editable via
`mkOutOfStoreSymlink`; `modules/darwin/services/aerospace/aerospace.toml` is in-store and
**needs `darwin-rebuild switch`**.

### 2.1 `config/sketchybar/items/mode.sh` — `update_freq=1` → `0`

The item is `drawing=off`. It was forking a shell, sourcing three files and running
`aerospace list-modes --current` 60 times a minute to decide not to draw.

```diff
 	script="$PLUGIN_DIR/mode.sh" \
-	update_freq=1 \
+	update_freq=0 \
```

It already subscribed to `aerospace_mode_change`, but nothing ever fired that event, so
§2.2 wires it. `plugins/mode.sh` honours a `MODE` environment variable
(`helpers/aerospace.sh: aerospace_current_mode`), so passing `MODE=` in the trigger means
the plugin does not even fork `aerospace` — the item becomes genuinely free.

**Undo:** set `update_freq=1` and revert §2.2.

### 2.2 `modules/darwin/services/aerospace/aerospace.toml` — fire the event

15 service-mode bindings and the one entry binding now trigger the event:

```diff
-alt-shift-semicolon = 'mode service'
+alt-shift-semicolon = ['mode service', 'exec-and-forget /run/current-system/sw/bin/sketchybar --trigger aerospace_mode_change MODE=service']
-esc = ['reload-config', 'mode main']
+esc = ['reload-config', 'mode main', 'exec-and-forget /run/current-system/sw/bin/sketchybar --trigger aerospace_mode_change MODE=main']
```

…and the same for `r`, `f`, `backspace`, `alt-shift-h/j/k/l`, `alt-1/2/3/b/c`,
`shift-down`.

Validated with the same parser Nix uses:
`nix eval --expr 'builtins.fromTOML (builtins.readFile …)'` → `modes=main,service
service-bindings=16`.

**VERIFIED end-to-end on the sketchybar side**, tested with the fixed config actually live
and `update_freq=0`:

```
before trigger                                    drawing=off label='main'
sketchybar --trigger aerospace_mode_change MODE=service   -> drawing=on  label='service'
sketchybar --trigger aerospace_mode_change MODE=main      -> drawing=off label='main'
```

So the item is fully functional with the poll removed. And passing `MODE=` does skip the
`aerospace` fork, as intended:

| `plugins/mode.sh` invocation | ms/invoke |
|---|---|
| no `MODE` set (the old polling path) | 21.3 |
| `MODE=main` (the new event path) | **14.2** |

The 7.1 ms difference is the `aerospace list-modes --current` fork (6.2 ms measured
independently in §1.2). The remaining 14.2 ms is now paid only when you actually change
mode — a few times a day instead of 86,400 times.

**Not yet verified:** the AeroSpace half, because the binding change is in-store and needs
`darwin-rebuild switch`. Test after rebuilding by pressing `alt-shift-;` and confirming
the mode pill appears.

**Undo:** `git checkout modules/darwin/services/aerospace/aerospace.toml`.

### 2.3 `config/sketchybar/plugins/cpu.sh` — one process-table walk

91.0 → 41.3 ms/invoke, and `items/cpu.sh` `update_freq=2` → `10`. Combined: 4.55% → 0.41%.

Removed: a second full `ps` walk, two `whoami` forks, and six `grep`/`sed`/`awk` forks.
One `ps -Axo pcpu,user,ucomm` piped to one `awk` now produces the system split, the user
split, the total and the top process together.

**Known-unfixed correctness bug, pre-existing:** `ps -o pcpu` is a process-*lifetime*
average, so this widget has never displayed current CPU load — it shows something closer
to "average since each process started". Making it correct needs a sampling source. The
brief's suggestion, the compiled event provider `sketchybar-system-stats`, is the right
fix; it removes the fork entirely rather than making it cheaper. I did not add it because
it is a new dependency and needs a rebuild — flagging rather than deciding.

A `sysctl -n vm.loadavg` variant was benchmarked at **7.7 ms** (vs 41.3) but reports load
average, not a percentage, and cannot produce the top-process popup row. Rejected as a
silent change of meaning; noted here in case you want it.

**Undo:** `git checkout config/sketchybar/plugins/cpu.sh config/sketchybar/items/cpu.sh`.

### 2.4 `net.activity` — new dedicated fast plugin

The graph item shared `plugins/wifi.sh`, which gathered SSID, link rate, VPN name and IP
for a popup the graph does not draw — including `scutil --nc list` (24.0 ms) and
`networksetup -listallhardwareports` (19.2 ms) **on a 2-second timer**.

New `plugins/net_activity.sh` reads interface byte counters and nothing else:
95.3 → 21.7 ms/invoke, `update_freq=2` → `10`. **4.77% → 0.22%.**

**Undo:** `rm config/sketchybar/plugins/net_activity.sh` and restore `items/wifi.sh`.

### 2.5 `helpers/network.sh` — the Wi-Fi widget was broken, and is not fixable

Confirmed the brief's finding and established that it cannot be repaired from a shell
script:

| method | result on macOS 26 |
|---|---|
| `airport -I` | binary **does not exist** on disk |
| `ipconfig getsummary en0` | `SSID : <redacted>` |
| `wdutil info` | empty without root |
| `networksetup -getairportnetwork en0` | "You are not associated with an AirPort network." |

Reading the SSID now requires root or a Location Services entitlement. A sketchybar plugin
has neither, and granting Location Services to a `/nix/store` binary would re-prompt on
every store path change.

So the dead code was **removed** rather than left silently returning empty strings:
`network_airport_bin`, `network_wifi_info`, `network_wifi_ssid`, `network_wifi_rate`, and
the `wifi.speed` popup row (which had been rendering `-- Mbps`). The existing
"Wi-Fi connected" / "Disconnected" fallback covers the display.

Also: the interface name is now cached in `$TMPDIR` instead of costing a 19.2 ms
`networksetup` fork per pass, and the four `awk` forks used for rate formatting were
merged into one.

**Undo:** `git checkout config/sketchybar/helpers/network.sh config/sketchybar/plugins/wifi.sh config/sketchybar/items/wifi.sh`.

### 2.6 `clock` — `update_freq=1` → `15`, drop `%S`

Seconds forced a 60/min fork. Cost table so you can choose:

| update_freq | cost (% of one core) | worst-case staleness |
|---|---|---|
| 1 (with `%S`) | 0.89 | 1 s |
| 15 (chosen) | 0.06 | 15 s |
| 60 (brief's suggestion) | 0.015 | 59 s |

I deviated from the brief's `60` deliberately: at `update_freq=60` the refresh is not
aligned to the minute boundary, so the displayed minute would be wrong for an average of
30 s out of every 60. `15` keeps 93% of the saving and bounds the error at 15 s.

**Undo:** `git checkout config/sketchybar/items/clock.sh config/sketchybar/plugins/clock.sh`.

### 2.7 `helpers/battery.sh` — one `pmset` instead of four

Four accessors each ran `pmset -g batt` (6.3 ms) for the same snapshot. Now cached in a
shell variable. Only 2 invocations/min, so this is worth ~0.05% — included because it is
free and obviously correct, not because it matters.

**Undo:** `git checkout config/sketchybar/helpers/battery.sh`.

---

## 3. Findings that need a decision from you

### 3.1 A Contacts/CardDAV account is in a failed-sync retry loop — biggest single win

This is the largest consumer on the machine after the browser/Electron apps, and it is not
in the original brief.

**Measured, every window, all day:**

| process | % of one core |
|---|---|
| `contactsd` | 5.9 – 6.9 |
| `AddressBookSourceSync` | 2.9 – 4.1 |
| `postersyncd` (Contacts.framework) | 0.5 – 0.7 |
| **total** | **~10** |

Evidence it is a failure loop, not normal syncing:

- **15 distinct `AddressBookSourceSync` PIDs in 20 minutes** — it respawns roughly every
  80 seconds.
- **101,675 unified-log lines in 10 minutes** (~170/second) from the two processes.
- Repeated `CFNetwork-AOSKit: Failed to get a X-mobile me token from AOSkit` — an iCloud
  token acquisition failure.
- Source breakdown in those logs: `carddav` 2370 mentions, `exchange` 540,
  `iCloudHelper` 119.
- `Group does not appear to be read-only` logged ~1000 times in 10 minutes — it is
  re-walking the same group set continuously.

**It also blocks idle sleep.** `pmset -g assertions`:

```
pid 71371(AddressBookSourceSync): PreventUserIdleSystemSleep named: "Address Book Source Sync"
```

That is a battery cost independent of the CPU cost, and it is the more important half.

**I cannot fix this and did not try** — it is an account credential problem, not config.
The fix is yours: System Settings → Internet Accounts, find the CardDAV/iCloud account
whose Contacts sync is failing, and either re-authenticate it or turn its Contacts toggle
off. Then re-check with:

```sh
/usr/bin/log show --predicate 'process == "AddressBookSourceSync"' --last 10m --info --style compact | wc -l
```

Healthy should be a few hundred lines, not 100,000.

### 3.2 `airportd` — ~4.9% of one core, cause identified, no safe lever

Sustained 4.38–5.45% across six windows (mean ~4.9, sd ~0.37). **Not** induced by
sketchybar — see §4.1, where I tested and refuted exactly that hypothesis.

`/usr/bin/log show` over 10 minutes: **31,823 lines**, of which `SCAN` 2081,
`awdl` 1239, `utun` 532, `anpi` 234, and `State:/Network/Global/IPv4` changing **345
times** — the global network state is flapping ~35×/min.

The `utun` churn is Tailscale and the `awdl` churn is AWDL. The obvious lever — turning
AirDrop off — is **still untested**: §4.2 explains how my A/B for it silently failed to
apply the treatment at all. **INFERENCE, untested:** the duplicate Tailscale service
registration (§3.5) is a plausible contributor to the `State:/Network/Global/IPv4` churn,
since two VPN services fighting over the default route would produce exactly this
signature. Testing that means unregistering one, which is §3.5.

### 3.3 `storagekitd` is in a Preboot update loop — CONFIRMED, and the prior pass was right for the wrong reason

The brief asked me to verify or kill this. **Verified**, with direct evidence rather than
the miscounted statistic the previous pass used.

`/usr/bin/log show --predicate 'process == "storagekitd"' --last 10m --info` →
**51,161 lines in 10 minutes** (~85/second), dominated by:

| repeated message | count / 10 min |
|---|---|
| `[diskmanagement:general] UpdatePreboot: <private>` | thousands, across many thread IDs |
| `(CFOpenDirectory) Querying records from directories` | 870 |
| `(CFOpenDirectory) Fetch updated record from directory` | 840 |
| `_DMProgressMarkerAdd IntErr=…` | 985 |
| `_DMArrayForKeyInDictionary DMErr=N err=N outArr=(null)` | 820 |
| lines matching `preboot\|retry\|error\|fail` | **20,680** |

And `efilogin-helper` respawned **40 distinct PIDs in 20 minutes** — roughly every 30
seconds.

So it is a genuine loop: repeatedly rebuilding the Preboot volume's user records, querying
OpenDirectory each time, and hitting `outArr=(null)` errors. `storagekitd` measured
**2.1–2.6% of one core in every one of the nine windows** in this audit, plus
`efilogin-helper` (~0.5% whenever it surfaces).

**This also explains most of `opendirectoryd`.** §1.3 showed only ~1.0 of `opendirectoryd`'s
2.4–3.2% was sketchybar's `whoami`/`ps` calls. The 870+840 directory queries per 10 minutes
from `storagekitd` account for a good share of the rest. Cluster total: **~3–5% of one core,
sustained.**

**Correcting the record on the prior pass's statistic:** it claimed 166 local users. Actual
count on this machine —

```
total dscl entries:  166
system (_ prefixed): 161
real users:          2      (Guestguest, romaingrx)
```

So "166 users" was indeed wrong, exactly as the brief suspected. The conclusion it was used
to support happens to be correct anyway, but it was not evidence for it. FileVault is **On**,
and a `Guestguest` account exists — a Guest user under FileVault is a plausible trigger for
repeated Preboot reconciliation. **INFERENCE, untested:** removing the Guest account may
stop the loop.

**Needs sudo, so it is yours to run.** The standard remedy is to force one clean Preboot
rebuild:

`/` resolves to `/dev/disk3s1s1` ("Macintosh HD", APFS), so this form is correct:

```sh
sudo diskutil apfs updatePreboot /
```

Then re-check — healthy is a few hundred lines, not 51,000:

```sh
/usr/bin/log show --predicate 'process == "storagekitd"' --last 10m --info --style compact | wc -l
```

I did not run it: it writes to the Preboot volume of a FileVault-encrypted disk, and that is
not something to do to someone's machine unasked.

### 3.4 `pmset` — display sleeps after 3 hours on battery

Confirmed from the brief. `displaysleep` is 180 minutes on **both** battery and AC; the
macOS default on battery is 2 minutes. A 3024×1964 XDR display left on for 3 hours after
you walk away is, in milliwatt terms, larger than everything else in this document
combined.

Not applied — it changes the live machine. nix-darwin's `power.sleep.*` wraps
`systemsetup` and cannot express separate battery/AC values, so this stays imperative
(brief §6), which means it belongs in `postActivation`:

```sh
sudo pmset -b displaysleep 5      # battery: 5 min
sudo pmset -c displaysleep 30     # AC: 30 min
```

**Undo:** `sudo pmset -b displaysleep 180 && sudo pmset -c displaysleep 180`.

### 3.5 Duplicate and dead network services

`scutil --nc list` confirms all three items from the brief:

```
* (Connected)      … VPN (io.tailscale.ipn.macsys) "Tailscale 3"
* (Disconnected)   … PPP --> MT65xx Preloader "MT65xx Preloader"
* (Disconnected)   … VPN (io.tailscale.ipn.macos) "Tailscale"
```

Two Tailscale services registered (Tailscale's own docs say the macsys and macos variants
conflict) plus a dead Android-bootloader PPP profile. Removing the two disconnected
services is safe housekeeping. **I did not measure a saving from this and do not claim
one** — both are disconnected, so at idle they likely cost nothing; the argument is
correctness and the §3.2 inference, not measured CPU.

Removal is via System Settings → Network → the "…" menu → Remove Service, or
`scutil --nc` / `networksetup -removenetworkservice`. Both need your confirmation because
removing the wrong VPN service would drop your Tailscale connectivity.

---

## 4. Tested and REJECTED

This list exists so the next pass does not re-litigate these. Everything here was measured,
not reasoned about.

### 4.1 "sketchybar's Wi-Fi widget is driving `airportd`" — REFUTED

My own hypothesis, and it was wrong. `wifi.sh` polls network state 32×/min, `airportd` was
the #3 consumer, and the AeroSpace precedent made induced cost look likely.

Measured: `airportd` was **4.63%** with sketchybar running and **5.04% / 5.18%** with it
booted out. It went *up*. The mechanism is now clear: `network_wifi_info` tests
`[ -x /System/.../airport ]`, the binary does not exist, and the function returns without
ever forking. **The widget was too broken to induce anything.**

### 4.2 AirDrop `Everyone` → `Off` — **NOT TESTED. My harness was broken.**

This entry originally read "tested, null result". That was wrong, and the error is worth
more than the experiment was.

`sharingd` caches `DiscoverableMode`; writing the preference does nothing until the daemon
reloads. My script did `defaults write` then
`launchctl kickstart -k gui/$UID/com.apple.sharingd`, and **that command fails on this
machine**:

```
Could not kickstart service "com.apple.sharingd":
150: Operation not permitted while System Integrity Protection is engaged
```

SIP forbids restarting Apple system agents. The script sent stderr to `/dev/null`, so the
failure was silent. `sharingd`'s PID was **764 before, during and after** the run — it
never restarted and never re-read the setting.

So the treatment was never applied. The numbers below are two samples of an unchanged
system:

| | "control" (`Everyone`) | "treatment" (`Everyone`, believed `Off`) |
|---|---|---|
| total, all processes | 81.02 | 71.84 |
| `airportd` | 5.45 | 4.38 |
| AWDL log lines/min | 625 | 633 |

The flat AWDL rate is exactly what a no-op produces. The 1.07 `airportd` difference is
ordinary window-to-window drift — its range across all nine windows in this audit was
4.38–5.45, which fully contains it.

**Status: the AirDrop lever is UNTESTED, not disproved.** Do not record it as ruled out.
Testing it needs the daemon to actually reload, and since SIP blocks `kickstart`, that
means toggling AirDrop through System Settings or Control Center by hand and then running
two windows. Whether that is worth your time: `airportd` is ~4.9% of one core, i.e. 0.3%
of this 16-core box.

**The generalisable lesson — this is the §4 trap #3 failure mode wearing a different hat.**
Trap #3 says a `kill` produces a treatment window that never happened. The same is true of
*any* treatment you verify by reading back the thing you wrote instead of observing the
system change behaviour. I checked `defaults read` and saw `Off`, which confirmed only
that my own write had landed. Two rules follow:

1. **Verify the effect, not the setting.** For a process, that means a PID change or the
   process being absent. For a daemon setting, it means the daemon restarting or an
   observable behaviour change.
2. **Never send a setup command's stderr to `/dev/null`.** The single line that would have
   caught this was suppressed by my own script.

The sketchybar A/Bs in §1.3 and §1.5 do not have this defect — see §1.3's verification
table.

### 4.3 `plugins/darkmode.sh` costs 1.61% of a core — WRONG, it is dead code

I measured `darkmode.sh` at 16.1 ms/invoke and, reading `items/darkside.sh`
(`update_freq=1`), projected 1.61% of a core. Then I checked the **running** bar:

```sh
sketchybar --query bar   # -> no "appearance" item
grep -c darkside config/sketchybar/sketchybarrc   # -> 0
```

`items/darkside.sh` is never sourced by `sketchybarrc`. The item does not exist and the
plugin never runs on a timer. **The real cost is zero.** `items/darkside.sh`,
`plugins/darkmode.sh` and `plugins/darkmode_click.sh` are dead files and could simply be
deleted — I left them alone, since deleting files you did not ask me to touch is not a
performance fix.

Lesson for the next pass: read `sketchybarrc`'s `source` list before costing any item.

### 4.4 Periodic launchd jobs — not a fork-tax source

Every `StartInterval` / `StartCalendarInterval` job on the machine:

| job | interval |
|---|---|
| `com.google.GoogleUpdater.wake` | 3600 s |
| `us.zoom.updater` | 3600 s |
| `com.microsoft.update.agent` | 7200 s |
| `org.nixos.nix-optimise` | weekly, Sun 04:15 |
| `com.teamviewer.UninstallerWatcher` | `WatchPaths`, not periodic |

Hourly is four orders of magnitude away from mattering. The brief's suspicion that another
double-digit win was hiding in launchd is **not supported** — the fork tax on this machine
was concentrated entirely in sketchybar.

### 4.5 `romaingrx-theme-watch` — real, but too small to bother with

`config/bin/romaingrx-theme-watch` polls every 2 s (`uname -s` + `defaults read -g
AppleInterfaceStyle` ≈ 6.3 ms) → **~0.19% of one core**. Never appeared above the 0.45%
cutoff in any window. Raising the interval to 5 s would save ~0.11%. Not worth a config
change; recorded so the next pass can skip it.

---

## 5. Methodology notes for the next pass

Three traps beyond the four already in the brief.

1. **`log` is shadowed by a zsh function in this environment.** `log show …` returns
   `(eval):log:1: too many arguments` and **zero lines**, which reads exactly like "this
   process produces no logs". My first three log queries returned 0 and were worthless.
   **Always use `/usr/bin/log`.** This one is dangerous because the failure is silent and
   looks like evidence of absence.

2. **`ps`-delta sampling cannot see short-lived forks.** A child born and reaped between
   the two snapshots is in neither, so it contributes nothing to the total. Any
   "system total CPU" built this way undercounts fork-heavy work — here by roughly 13
   percentage points. Use `os.times()` child accounting for anything that spawns helpers.
   §1.4 has the arithmetic.

3. **Config files are not the running configuration.** `items/darkside.sh` looked like a
   60/min poller and was dead code (§4.3). Query the daemon, not the repo.

4. **Verify the effect, not the setting — and never `2>/dev/null` a setup command.** This
   one caught me (§4.2). Brief trap #3 warns that `kill` on a `KeepAlive` agent gives you a
   treatment window that never happened; the same is true of *any* treatment confirmed by
   reading back the value you just wrote. I ran `defaults write`, then `defaults read`, saw
   the new value, and called it verified — but the daemon that caches it had never
   reloaded, because `launchctl kickstart` on an Apple system agent is **blocked by SIP**
   and I had discarded its stderr. Check for a PID change, an absent process, or an
   observable behaviour change. On this machine specifically: **you cannot `kickstart`,
   `bootout` or otherwise restart Apple's own launchd services while SIP is on.** That rules
   out the whole class of "flip an Apple daemon's preference and A/B it" experiments unless
   the toggle is done through the UI.

Also confirmed from the brief: `pmset -g assertions` remains worth checking — beyond the
known Claude `NoIdleSleepAssertion`, it is what surfaced §3.1.

**Not attempted in this pass:** the ProMotion 120 Hz vs 60 Hz A/B and the Reduce
Transparency A/B (brief §5.4). Both need `sudo powermetrics` for a meaningful answer,
since CPU% excludes the GPU and the target is a GPU compositor. Both want you at the
keyboard.

The `storagekitd` / Preboot question (brief §5.6) is **resolved** — see §3.3. It did not
need sudo to establish; the unified log was readable as a normal user once `/usr/bin/log`
was used instead of the shadowed `log`. Only the *fix* needs sudo.

---

## 6. Action list

Ordered by (measured value x how little effort it costs you). Every command here is
copy-pasteable and has a verification step, because a fix you cannot confirm is a fix you
will re-litigate next month.

### A. Today, ~5 minutes, biggest wins

**A1 — Fix the failing Contacts account.** ~10% of one core, and it is the only thing on
this machine holding a sleep assertion. System Settings -> General -> Internet Accounts,
find the CardDAV/iCloud account whose Contacts sync is failing, and either re-authenticate
it or turn its **Contacts** toggle off.

```sh
# before: expect ~100,000
/usr/bin/log show --predicate 'process == "AddressBookSourceSync"' --last 10m --info --style compact | wc -l
# after: expect a few hundred. also confirm the sleep assertion is gone:
pmset -g assertions | grep -i "Address Book" || echo "sleep assertion cleared"
```

**A2 — Stop the display staying on for 3 hours on battery.** Not CPU, but in milliwatts
almost certainly the largest single item in this document.

```sh
sudo pmset -b displaysleep 5 && sudo pmset -c displaysleep 30
# verify (this exact form is tested; a plain `grep -A1 Battery` misses it):
pmset -g custom | awk '/^Battery Power/,/^AC Power/' | grep displaysleep
# undo: sudo pmset -b displaysleep 180 && sudo pmset -c displaysleep 180
```

### B. This week, needs sudo, one command each

**B3 — Break the `storagekitd` Preboot loop.** ~3-5% of one core, sustained.

`/` resolves to `/dev/disk3s1s1` ("Macintosh HD", APFS), so this form is correct:

```sh
sudo diskutil apfs updatePreboot /
# verify — before: 51,161 lines. healthy: a few hundred.
/usr/bin/log show --predicate 'process == "storagekitd"' --last 10m --info --style compact | wc -l
```

**B4 — If B3 does not stick, remove the `Guestguest` account.** INFERENCE, untested: a
Guest account under FileVault is a plausible trigger for repeated Preboot reconciliation.
System Settings -> Users & Groups. Re-run B3's verification afterwards.

### C. Merge the status-bar work

**C5 —** Nothing here touches the live machine until you do this.

```sh
cd ~/.dotfiles && git merge romaingrx/perf-audit
launchctl kickstart -k gui/$UID/org.nixos.sketchybar   # sketchybar: live, no rebuild
darwin-rebuild switch                                   # required ONLY for aerospace.toml
```

Then confirm the AeroSpace half of the mode trigger, which is the one piece this audit
could not verify without a rebuild: press `alt-shift-;` and check the mode pill appears,
then `esc` and check it disappears.

### D. Housekeeping, no measured saving, do it when convenient

**D6 — Remove the dead network services.** A dead `MT65xx Preloader` PPP profile and a
disconnected duplicate Tailscale registration (Tailscale's docs say the macsys and macos
variants conflict). System Settings -> Network -> "..." -> Remove Service. **Keep
"Tailscale 3" (io.tailscale.ipn.macsys), the connected one.**

**D7 — Delete the dead sketchybar files.** `items/darkside.sh`, `plugins/darkmode.sh`,
`plugins/darkmode_click.sh` — never sourced by `sketchybarrc`, see §4.3. I left them alone
because deleting untouched files is not a performance fix, but they are pure noise.

### E. Still open — needs you at the keyboard

**E8 — The AirDrop lever is untested, not ruled out** (§4.2). SIP blocks restarting
`sharingd`, so it cannot be A/B'd from a script. Toggle AirDrop to "Receiving Off" in
Control Center by hand, leave it 5 minutes, and compare:

```sh
/usr/bin/log show --predicate 'eventMessage CONTAINS "awdl"' --last 1m --style compact | wc -l
```

Worth ~4.9% of one core if it works, which is 0.3% of this box. Low priority.

**E9 — ProMotion 120 Hz vs 60 Hz, and Reduce Transparency** (brief §5.4). Both untouched
this pass. CPU% is the wrong metric — these target the GPU compositor, and macOS Energy
Impact excludes GPU. They need:

```sh
sudo powermetrics --samplers cpu_power,gpu_power -i 5000 -n 12
```

run under each setting, with the Claude app both streaming and idle.

**E10 — Make the CPU widget correct.** It has never shown current CPU load (§2.3);
`ps -o pcpu` is a lifetime average. The fix is the compiled event provider
`sketchybar-system-stats` (Rust, in nixpkgs), which also removes the fork entirely rather
than making it cheaper. New dependency plus a rebuild, so it is your call.

---

## 7. Verification and undo

Everything toggled during this audit was restored in the same command via a shell `trap`,
and every restore was verified:

| experiment | restore verified by |
|---|---|
| sketchybar bootout | `pgrep -x sketchybar` non-empty after `bootstrap` |
| AirDrop `Off` | `defaults read com.apple.sharingd DiscoverableMode` → `Everyone`. Doubly safe: per §4.2 `sharingd` never reloaded the preference in the first place (PID 764 throughout), so its effective state was never altered. |
| config symlink swap | `readlink ~/.config/sketchybar` matches original; `wifi.speed` item present again |

Current machine state: **unchanged from before this audit.** The config edits live only in
this worktree.

To undo everything applied here: `git checkout config/sketchybar modules/darwin/services/aerospace/aerospace.toml`
and `rm config/sketchybar/plugins/net_activity.sh`.

To apply: merge this branch into `~/.dotfiles`, then

```sh
launchctl kickstart -k gui/$UID/org.nixos.sketchybar   # sketchybar config: live, no rebuild
darwin-rebuild switch                                   # required for aerospace.toml only
```
