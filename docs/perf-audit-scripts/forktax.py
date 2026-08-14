#!/usr/bin/env python3
"""Fork-tax replay harness.

Per PERF-AUDIT-BRIEF section 4 rule 2: forked children are invisible to Activity
Monitor. This replays a plugin script N times and measures:

  (a) TRUE SUBTREE COST via os.times() child accounting — children_user +
      children_system. This captures every bash/ps/awk/networksetup fork.
  (b) INDUCED DAEMON COST — cumulative CPU-time deltas for system daemons during
      the replay. This is how the AeroSpace-induced-by-sketchybar finding was made,
      generalised to every daemon.

Replays run with the REAL environment of the running sketchybar daemon (captured
via `ps eww`), because plugins are spawned by the daemon, not by sketchybarrc, and
therefore do NOT inherit sketchybarrc's exports.

Usage: forktax.py N script.sh[:NAME] [script.sh:NAME ...]
"""
import os
import subprocess
import sys
import time

DAEMONS = [
    "airportd", "AeroSpace", "configd", "WiFiAgent", "launchd", "notifyd",
    "cfprefsd", "opendirectoryd", "sketchybar", "contactsd", "storagekitd",
    "WindowServer", "launchservicesd", "logd", "mds_stores", "nehelper",
    "DriverKit-AppleBCMWLAN", "networkserviceproxy", "symptomsd", "trustd",
]


def daemon_snapshot():
    out = subprocess.run(
        ["ps", "-Axo", "pid=,time=,comm="], capture_output=True, text=True
    ).stdout
    acc = {}
    for line in out.splitlines():
        parts = line.split(None, 2)
        if len(parts) < 3:
            continue
        _pid, tm, comm = parts
        days = 0
        if "-" in tm:
            ds, tm = tm.split("-", 1)
            days = int(ds)
        bits = [float(x) for x in tm.split(":")]
        while len(bits) < 3:
            bits.insert(0, 0.0)
        secs = days * 86400 + bits[0] * 3600 + bits[1] * 60 + bits[2]
        base = comm.rsplit("/", 1)[-1]
        for d in DAEMONS:
            if d in base or d in comm:
                acc[d] = acc.get(d, 0.0) + secs
                break
    return acc


def sketchybar_env():
    """Capture the real launchd environment of the running sketchybar daemon."""
    env = dict(os.environ)
    pid = subprocess.run(
        ["pgrep", "-x", "sketchybar"], capture_output=True, text=True
    ).stdout.split()
    if pid:
        out = subprocess.run(
            ["ps", "eww", "-o", "command=", "-p", pid[0]], capture_output=True, text=True
        ).stdout
        for tok in out.split():
            if "=" in tok and tok.split("=", 1)[0].isupper():
                k, v = tok.split("=", 1)
                env[k] = v
    env.setdefault("SENDER", "routine")
    return env


def replay(script, n, name, env):
    e = dict(env)
    e["NAME"] = name
    devnull = subprocess.DEVNULL

    t0 = time.time()
    c0 = os.times()
    d0 = daemon_snapshot()
    for _ in range(n):
        subprocess.run(["/bin/bash", script], stdout=devnull, stderr=devnull, env=e)
    d1 = daemon_snapshot()
    c1 = os.times()
    t1 = time.time()

    wall = t1 - t0
    subtree = (c1.children_user - c0.children_user) + (
        c1.children_system - c0.children_system
    )
    induced = {k: d1.get(k, 0) - d0.get(k, 0) for k in d1}
    induced = {k: v for k, v in induced.items() if v > 0.02}
    return wall, subtree, induced


def main():
    n = int(sys.argv[1])
    env = sketchybar_env()
    print(f"# replay env keys: CONFIG_DIR={env.get('CONFIG_DIR', '(unset — resolved by env.sh)')}")
    print(f"# n={n} per script\n")

    print(f"{'script':<22} {'wall_s':>7} {'subtree_s':>10} {'ms/invoke':>10}   induced daemon CPU-seconds")
    print("-" * 118)
    results = []
    for spec in sys.argv[2:]:
        script, _, name = spec.partition(":")
        name = name or os.path.basename(script).replace(".sh", "")
        wall, subtree, induced = replay(script, n, name, env)
        per = subtree / n * 1000
        ind = "  ".join(
            f"{k}={v:.2f}" for k, v in sorted(induced.items(), key=lambda x: -x[1])
        )
        base = os.path.basename(script)
        print(f"{base:<22} {wall:7.1f} {subtree:10.2f} {per:10.1f}   {ind}")
        results.append((base, per, induced, n, wall))

    print()
    print("### Projected steady-state cost (% of ONE core) at configured update_freq")
    print(f"{'script':<22} {'freq(/min)':>11} {'own %core':>10}   induced %core (extrapolated)")
    print("-" * 100)
    # invocations per minute as configured today
    FREQ = {
        "mode.sh": 60, "darkmode.sh": 60, "clock.sh": 60,
        "cpu.sh": 30, "wifi.sh": 32, "battery.sh": 2,
    }
    for base, per, induced, nn, wall in results:
        f = FREQ.get(base, 60)
        own = per / 1000 * f / 60 * 100
        ind_pct = {k: (v / nn) * f / 60 * 100 for k, v in induced.items()}
        ind_s = "  ".join(
            f"{k}={v:.2f}%" for k, v in sorted(ind_pct.items(), key=lambda x: -x[1]) if v > 0.05
        )
        print(f"{base:<22} {f:11d} {own:10.2f}   {ind_s}")


if __name__ == "__main__":
    main()
