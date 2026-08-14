#!/usr/bin/env python3
"""Independent confirmation of the sketchybar fork cost, via `top` kernel counters.

The audit's 12.85% / 0.98% figures come from os.times() child accounting. This
re-derives them from `top -l 2`, which reads the kernel's own aggregate CPU tick
counters — a different mechanism with no shared code path.

Two earlier attempts were tried and REJECTED by their own validation step:
  - PID-allocation counting: injected 500 processes, counter saw 163. Darwin
    reuses recently-freed PIDs, so it undercounts exactly the short-lived-process
    workload of interest.
  - Raw host_statistics via ctypes: my tick-rate calibration reported 3.1 cores
    busy on an idle machine. `top` does this arithmetic correctly, so use `top`.

Amplification: at real polling rates the OLD config costs ~12.85% of one core =
0.80% of a 16-core box, which is below confounder noise. Replaying the schedule
as fast as possible amplifies it ~10-20x into a trivially detectable signal, then
we divide back down by the number of schedule-minutes actually completed.

Per brief §4 rule 1: only the SECOND `top` sample is ever used.

Usage: topconfirm.py OLD_CFG NEW_CFG WINDOW_SECONDS
"""
import os
import re
import subprocess
import sys
import threading
import time

NCPU = os.cpu_count()


def top_busy_pct_of_one_core(window):
    """Busy CPU over `window` seconds, as % of ONE core. Second sample only."""
    out = subprocess.run(
        ["top", "-l", "2", "-n", "0", "-s", str(int(window))],
        capture_output=True, text=True,
    ).stdout
    samples = re.findall(
        r"CPU usage:\s*([\d.]+)%\s*user,\s*([\d.]+)%\s*sys,\s*([\d.]+)%\s*idle", out
    )
    if len(samples) < 2:
        raise RuntimeError(f"could not parse two top samples: {samples}")
    user, sysp, idle = (float(x) for x in samples[1])  # SECOND sample only
    return (user + sysp) * NCPU  # top reports % of total capacity


def old_schedule(cfg):
    p = f"{cfg}/plugins"
    return [(f"{p}/mode.sh", "mode.indicator", 60), (f"{p}/clock.sh", "clock", 60),
            (f"{p}/cpu.sh", "cpu.user", 30), (f"{p}/wifi.sh", "net.activity", 30),
            (f"{p}/wifi.sh", "wifi.control", 2), (f"{p}/battery.sh", "battery", 2)]


def new_schedule(cfg):
    p = f"{cfg}/plugins"
    return [(f"{p}/clock.sh", "clock", 4), (f"{p}/cpu.sh", "cpu.user", 6),
            (f"{p}/net_activity.sh", "net.activity", 6),
            (f"{p}/wifi.sh", "wifi.control", 2), (f"{p}/battery.sh", "battery", 2)]


def sketchybar_env():
    env = dict(os.environ)
    pid = subprocess.run(["pgrep", "-x", "sketchybar"], capture_output=True, text=True).stdout.split()
    if pid:
        out = subprocess.run(["ps", "eww", "-o", "command=", "-p", pid[0]],
                             capture_output=True, text=True).stdout
        for tok in out.split():
            if "=" in tok and tok.split("=", 1)[0].isupper():
                k, v = tok.split("=", 1)
                env[k] = v
    env.setdefault("SENDER", "routine")
    return env


class Replayer(threading.Thread):
    """Replays a whole schedule-minute per iteration until told to stop."""

    def __init__(self, schedule, env):
        super().__init__(daemon=True)
        self.schedule, self.env = schedule, env
        self.stop = threading.Event()
        self.minutes_done = 0.0

    def run(self):
        devnull = subprocess.DEVNULL
        while not self.stop.is_set():
            for path, name, count in self.schedule:
                e = dict(self.env)
                e["NAME"] = name
                for _ in range(count):
                    if self.stop.is_set():
                        return
                    subprocess.run(["/bin/bash", path], stdout=devnull, stderr=devnull, env=e)
            self.minutes_done += 1


def measure(label, schedule, env, window, baseline):
    r = Replayer(schedule, env)
    t0 = time.time()
    r.start()
    time.sleep(5)                       # let it reach steady state
    busy = top_busy_pct_of_one_core(window)
    r.stop.set()
    r.join(timeout=30)
    elapsed = time.time() - t0
    rate = r.minutes_done / elapsed     # schedule-minutes replayed per wall second
    attributable = busy - baseline      # % of one core, at the AMPLIFIED rate
    # cost of ONE schedule-minute, expressed as steady-state % of one core
    real = attributable / (rate * 60) if rate > 0 else float("nan")
    print(f"{label:<12} busy={busy:7.2f}%  minus baseline {baseline:6.2f}%"
          f"  -> {attributable:7.2f}% at {rate * 60:5.1f}x real rate"
          f"  => steady-state {real:6.2f}% of one core")
    return real


def main():
    old_cfg, new_cfg, window = sys.argv[1], sys.argv[2], float(sys.argv[3])
    env = sketchybar_env()
    print(f"### Independent confirmation via `top` kernel counters ({NCPU} cores)\n")

    baseline = top_busy_pct_of_one_core(window)
    print(f"{'baseline':<12} busy={baseline:7.2f}% of one core (system idle, nothing replayed)\n")

    old = measure("OLD config", old_schedule(old_cfg), env, window, baseline)
    new = measure("NEW config", new_schedule(new_cfg), env, window, baseline)

    print()
    print(f"{'':<22}{'top (independent)':>20}{'os.times() (audit)':>22}")
    print(f"  {'OLD steady-state':<20}{old:19.2f}%{12.85:21.2f}%")
    print(f"  {'NEW steady-state':<20}{new:19.2f}%{0.98:21.2f}%")
    print(f"  {'SAVING (fork half)':<20}{old - new:19.2f}%{11.87:21.2f}%")


if __name__ == "__main__":
    main()
