#!/usr/bin/env python3
"""Direct fork-rate counter — the instrument itself never forks.

Samples the kernel's process list via libproc's proc_listallpids() (one syscall,
returns an int array) at high frequency from inside this process, and counts PIDs
that appear which were not present in the previous sample. That is a direct count
of process creations, independent of CPU accounting entirely.

Why not the two rejected approaches:
  - PID-allocation delta: validation injected 500 processes, counter saw 163,
    because Darwin reuses recently-freed PIDs.
  - `pgrep`/`ps` polling: the instrument would fork once per sample, swamping the
    signal it is trying to measure.

PID reuse is harmless here: a reused PID that was absent in the previous sample
and present in this one is genuinely a new process.

Blind spot: processes living less than the sample interval can be missed. That is
why `validate` exists — it injects a known number of real forks with a realistic
lifetime and reports the capture rate, so the undercount is quantified rather than
assumed. Both configs are measured with the same instrument, so the capture rate
cancels in the ratio.

Usage: forkcount.py validate | forkcount.py measure SECONDS [label]
"""
import ctypes
import ctypes.util
import subprocess
import sys
import time

_libc = ctypes.CDLL(ctypes.util.find_library("c"), use_errno=True)
_libc.proc_listallpids.restype = ctypes.c_int
_libc.proc_listallpids.argtypes = [ctypes.c_void_p, ctypes.c_int]

_CAP = 8192
_BUF = (ctypes.c_int32 * _CAP)()
_NBYTES = ctypes.sizeof(_BUF)


def live_pids():
    n = _libc.proc_listallpids(ctypes.byref(_BUF), _NBYTES)
    if n <= 0:
        raise OSError("proc_listallpids failed")
    return frozenset(_BUF[:n])


def count_forks(seconds, interval=0.001):
    """Count process creations over `seconds`. Returns (count, elapsed, samples)."""
    prev = live_pids()
    seen = 0
    samples = 0
    t0 = time.time()
    end = t0 + seconds
    while time.time() < end:
        cur = live_pids()
        seen += len(cur - prev)
        prev = cur
        samples += 1
        time.sleep(interval)
    return seen, time.time() - t0, samples


def main():
    mode = sys.argv[1]

    if mode == "validate":
        # Inject N real forks with a realistic (short) lifetime and see how many
        # the sampler catches. This quantifies the blind spot instead of ignoring it.
        import threading

        N = 300
        done = threading.Event()

        def inject():
            time.sleep(1.0)
            for _ in range(N):
                subprocess.run(["/bin/bash", "-c", ":"])
            done.set()

        base, base_el, _ = count_forks(6.0)
        t = threading.Thread(target=inject, daemon=True)
        t.start()
        got, el, samples = count_forks(6.0)
        t.join(timeout=10)
        attributed = got - base * (el / base_el)
        rate = attributed / N * 100
        print("### fork-counter validation")
        print(f"  sample interval    : ~{el / samples * 1000:.2f} ms ({samples} samples in {el:.1f}s)")
        print(f"  background forks   : {base} in {base_el:.1f}s")
        print(f"  with {N} injected  : {got} in {el:.1f}s")
        print(f"  attributed         : {attributed:.0f} of {N}  -> capture rate {rate:.0f}%")
        print(f"  VERDICT: {'usable — capture rate is high and quantified' if rate > 70 else 'capture rate too low, ratio still valid but absolutes are not'}")
        return

    secs = float(sys.argv[2])
    label = sys.argv[3] if len(sys.argv) > 3 else ""
    n, el, samples = count_forks(secs)
    print(f"{label:<34} {n:6d} forks in {el:5.1f}s = {n / el * 60:7.0f} forks/min"
          f"   ({samples} samples)")


if __name__ == "__main__":
    main()
