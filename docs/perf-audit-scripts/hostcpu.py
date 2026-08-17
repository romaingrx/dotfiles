#!/usr/bin/env python3
"""Independent confirmation of the sketchybar saving via kernel CPU tick counters.

The 12.85%/0.98% figures in the audit come from os.times() child accounting. This
script re-derives them from a completely different instrument: the Mach
host_statistics(HOST_CPU_LOAD_INFO) counter, which is the kernel's own aggregate
tick tally across all CPUs. It shares no code path with rusage or with ps.

Method: replay a whole minute's worth of each config's polling schedule, and measure
the system-wide busy-tick delta, minus the idle baseline rate x the same duration.
Replaying many minutes' worth amplifies the signal far above confounder noise.

The PID-allocation approach was tried first and REJECTED: validation injected 500
processes and the PID counter saw 163, because Darwin reuses recently-freed PIDs.

Usage: hostcpu.py validate | hostcpu.py compare OLD_CFG NEW_CFG MINUTES
"""
import ctypes
import ctypes.util
import os
import subprocess
import sys
import time

HOST_CPU_LOAD_INFO = 3
CPU_STATE_MAX = 4
CPU_STATE_USER, CPU_STATE_SYSTEM, CPU_STATE_IDLE, CPU_STATE_NICE = 0, 1, 2, 3

_libc = ctypes.CDLL(ctypes.util.find_library("c"), use_errno=True)


class HostCPULoadInfo(ctypes.Structure):
    _fields_ = [("cpu_ticks", ctypes.c_uint * CPU_STATE_MAX)]


_libc.mach_host_self.restype = ctypes.c_uint
_HOST = _libc.mach_host_self()


def cpu_ticks():
    """(busy_ticks, total_ticks) aggregated across all cores, straight from the kernel."""
    info = HostCPULoadInfo()
    count = ctypes.c_uint(CPU_STATE_MAX)
    rc = _libc.host_statistics(
        _HOST, HOST_CPU_LOAD_INFO, ctypes.byref(info), ctypes.byref(count)
    )
    if rc != 0:
        raise OSError(f"host_statistics failed: {rc}")
    t = info.cpu_ticks
    busy = t[CPU_STATE_USER] + t[CPU_STATE_SYSTEM] + t[CPU_STATE_NICE]
    return busy, busy + t[CPU_STATE_IDLE]


NCPU = os.cpu_count()
HZ = 100  # Darwin ticks are 100 Hz per core for this counter


def busy_core_seconds(fn):
    """Run fn(); return (busy core-seconds consumed system-wide, wall seconds)."""
    b0, _ = cpu_ticks()
    t0 = time.time()
    fn()
    t1 = time.time()
    b1, _ = cpu_ticks()
    return (b1 - b0) / HZ, t1 - t0


# One minute of each config's real polling schedule: (plugin path, item NAME, count)
def old_schedule(cfg):
    p = f"{cfg}/plugins"
    return [
        (f"{p}/mode.sh", "mode.indicator", 60),
        (f"{p}/clock.sh", "clock", 60),
        (f"{p}/cpu.sh", "cpu.user", 30),
        (f"{p}/wifi.sh", "net.activity", 30),
        (f"{p}/wifi.sh", "wifi.control", 2),
        (f"{p}/battery.sh", "battery", 2),
    ]


def new_schedule(cfg):
    p = f"{cfg}/plugins"
    return [
        (f"{p}/clock.sh", "clock", 4),
        (f"{p}/cpu.sh", "cpu.user", 6),
        (f"{p}/net_activity.sh", "net.activity", 6),
        (f"{p}/wifi.sh", "wifi.control", 2),
        (f"{p}/battery.sh", "battery", 2),
    ]


def run_schedule(schedule, minutes, env):
    devnull = subprocess.DEVNULL

    def go():
        for _ in range(minutes):
            for path, name, count in schedule:
                e = dict(env)
                e["NAME"] = name
                for _ in range(count):
                    subprocess.run(["/bin/bash", path], stdout=devnull, stderr=devnull, env=e)

    return go


def sketchybar_env():
    env = dict(os.environ)
    pid = subprocess.run(["pgrep", "-x", "sketchybar"], capture_output=True, text=True).stdout.split()
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


def main():
    if sys.argv[1] == "validate":
        # Burn exactly one core for 8 seconds; the counter must see ~8 core-seconds.
        def spin():
            end = time.time() + 8
            while time.time() < end:
                pass

        idle_busy, idle_wall = busy_core_seconds(lambda: time.sleep(8))
        spin_busy, spin_wall = busy_core_seconds(spin)
        attributed = spin_busy - idle_busy
        err = (attributed - 8) / 8 * 100
        print("### host_statistics tick-counter validation")
        print(f"  cores={NCPU}  tick rate={HZ} Hz/core")
        print(f"  idle 8s        : {idle_busy:6.2f} busy core-seconds (background)")
        print(f"  spin 1 core 8s : {spin_busy:6.2f} busy core-seconds")
        print(f"  attributed     : {attributed:6.2f}  (expected 8.00, error {err:+.1f}%)")
        print(f"  VERDICT: {'counter is trustworthy' if abs(err) < 10 else 'UNRELIABLE'}")
        return

    _, _, old_cfg, new_cfg, minutes = sys.argv
    minutes = int(minutes)
    env = sketchybar_env()

    print(f"### Independent confirmation via kernel tick counters")
    print(f"# replaying {minutes} minutes' worth of each polling schedule")
    print(f"# baseline = system idle load, subtracted at the same wall rate\n")

    # baseline: what the system burns on its own, per second
    base_busy, base_wall = busy_core_seconds(lambda: time.sleep(30))
    base_rate = base_busy / base_wall
    print(f"baseline system load      : {base_rate * 100:6.2f}% of one core"
          f"  ({base_rate / NCPU * 100:.2f}% of the {NCPU}-core box)")

    results = {}
    for label, sched, cfg in (("OLD", old_schedule(old_cfg), old_cfg),
                              ("NEW", new_schedule(new_cfg), new_cfg)):
        busy, wall = busy_core_seconds(run_schedule(sched, minutes, env))
        attributable = busy - base_rate * wall
        per_min = attributable / minutes
        results[label] = per_min
        print(f"{label} config, {minutes} min replayed : {busy:7.2f} busy core-s over {wall:6.1f}s wall"
              f"  -> {attributable:7.2f} core-s attributable = {per_min * 100 / 60:6.2f}% of one core")

    old, new = results["OLD"], results["NEW"]
    print()
    print(f"  OLD steady-state cost : {old * 100 / 60:6.2f}% of one core   (os.times() said 12.85)")
    print(f"  NEW steady-state cost : {new * 100 / 60:6.2f}% of one core   (os.times() said  0.98)")
    print(f"  SAVING (fork half)    : {(old - new) * 100 / 60:6.2f}% of one core   (os.times() said 11.87)")


if __name__ == "__main__":
    main()
