#!/usr/bin/env python3
"""Cumulative CPU-time delta sampler.

Per PERF-AUDIT-BRIEF section 4 rule 1: `ps -o %cpu` on macOS is a process-LIFETIME
average and is useless for "what is busy now". This samples `ps -o time=` (cumulative
CPU seconds) at T0 and T1 and divides the delta by measured wall-clock.

Output is % of ONE core. The machine has 16, so 100% here = 6.25% of the box.

Usage: cpudelta.py SECONDS [label]
"""
import subprocess
import sys
import time


def snap():
    """pid -> (cpu_seconds, command)"""
    out = subprocess.run(
        ["ps", "-Axo", "pid=,time=,comm="], capture_output=True, text=True
    ).stdout
    d = {}
    for line in out.splitlines():
        parts = line.split(None, 2)
        if len(parts) < 3:
            continue
        pid, tm, comm = parts
        # ps time format: [DD-]HH:MM:SS.ss or MM:SS.ss
        days = 0
        if "-" in tm:
            ds, tm = tm.split("-", 1)
            days = int(ds)
        bits = [float(x) for x in tm.split(":")]
        while len(bits) < 3:
            bits.insert(0, 0.0)
        secs = days * 86400 + bits[0] * 3600 + bits[1] * 60 + bits[2]
        d[pid] = (secs, comm)
    return d


def main():
    window = float(sys.argv[1]) if len(sys.argv) > 1 else 30.0
    label = sys.argv[2] if len(sys.argv) > 2 else ""

    t0 = time.time()
    a = snap()
    time.sleep(window)
    b = snap()
    t1 = time.time()
    elapsed = t1 - t0

    rows = []
    for pid, (secs, comm) in b.items():
        prev = a.get(pid)
        if prev is None:
            # process started inside the window: all its CPU time is in-window
            rows.append((secs / elapsed * 100, secs, comm, pid, "NEW"))
        else:
            delta = secs - prev[0]
            if delta > 0:
                rows.append((delta / elapsed * 100, delta, comm, pid, ""))

    rows.sort(reverse=True)
    total = sum(r[0] for r in rows)

    print(f"### {label}  window={elapsed:.1f}s  (% of ONE core)")
    print(f"{'%core':>7} {'cpu_s':>7}  {'pid':>7}  command")
    for pct, delta, comm, pid, flag in rows[:30]:
        if pct < 0.05:
            break
        print(f"{pct:7.2f} {delta:7.2f}  {pid:>7}  {comm[:88]} {flag}")
    print(f"{'-'*60}")
    print(f"{total:7.2f} TOTAL across all processes (% of one core; 1600 = box saturated)")


if __name__ == "__main__":
    main()
