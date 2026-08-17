#!/usr/bin/env python3
"""Count process creations by PID allocation delta.

Independent of os.times() child accounting and of ps CPU sampling. Darwin assigns
PIDs from a monotonically increasing counter that wraps at PID_MAX (99999), so the
difference between two PIDs sampled W seconds apart is the number of processes
created system-wide in that window.

Costs exactly TWO forks per measurement, so the instrument barely perturbs what it
measures — unlike rapid `ps` polling, which would swamp the signal it is looking for.

Caveat: after wrap the kernel skips PIDs already in use. With ~700 live processes in
a 100000-wide space that is a ~0.7% undercount. Irrelevant at the signal sizes here.

Usage: forkrate.py validate|measure SECONDS [label]
"""
import subprocess
import sys
import time

PID_MAX = 100000


def pid_now():
    """Spawn one trivial process and return its PID."""
    p = subprocess.Popen(["/usr/bin/true"])
    p.wait()
    return p.pid


def burn(n):
    """Create exactly n processes."""
    for _ in range(n):
        subprocess.run(["/usr/bin/true"])


def window(seconds, inject=0):
    a = pid_now()
    t0 = time.time()
    if inject:
        burn(inject)
    remaining = seconds - (time.time() - t0)
    if remaining > 0:
        time.sleep(remaining)
    b = pid_now()
    elapsed = time.time() - t0
    # the two pid_now() calls and the injected burn are themselves forks;
    # subtract the instrument's own contribution (1 fork between the samples)
    forks = (b - a) % PID_MAX - 1
    return forks, elapsed


def main():
    mode = sys.argv[1]
    secs = float(sys.argv[2])
    label = sys.argv[3] if len(sys.argv) > 3 else ""

    if mode == "validate":
        # Does the counter track reality? Inject a known number of forks.
        base, e1 = window(secs)
        inj = 500
        withinj, e2 = window(secs, inject=inj)
        observed = withinj - base
        err = (observed - inj) / inj * 100
        print(f"### PID-counter validation")
        print(f"  background only      : {base:6d} forks in {e1:.1f}s")
        print(f"  background + {inj:4d}   : {withinj:6d} forks in {e2:.1f}s")
        print(f"  attributed to inject : {observed:6d}  (expected {inj}, error {err:+.1f}%)")
        ok = abs(err) < 10
        print(f"  VERDICT: {'counter is trustworthy' if ok else 'COUNTER UNRELIABLE — do not use'}")
        return

    forks, elapsed = window(secs)
    print(f"{label:<44} {forks:7d} forks in {elapsed:5.1f}s = {forks / elapsed * 60:8.0f} forks/min")


if __name__ == "__main__":
    main()
